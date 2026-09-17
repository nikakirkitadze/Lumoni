/**
 * Account deletion.
 *
 * `deleteAccount` is the callable the apps use. It has to answer quickly and
 * be safe to retry, so it only does the work a client is waiting on:
 *
 *   1. tombstone the uid (the rules and every callable refuse writes from a
 *      tombstoned uid, and the sweep finds unfinished work through it),
 *   2. delete the Auth user (which also invalidates its refresh tokens),
 *   3. `quickPurge` — every per-user document, but not ranking entries or
 *      leaderboard snapshots, which are slow to scrub.
 *
 * The full purge (`purgeUserData`) = quickPurge + ranking-entry-driven
 * snapshot scrubbing + a scrub of every snapshot generated around the
 * deletion time (and, from the sweep, around the previous sweep). It runs from
 * `onAuthUserDeleted` (fired by step 2) and again from `sweepDeletedUsers`,
 * which also finishes deletions whose callable died between the tombstone and
 * `deleteUser`.
 *
 * Snapshot builds (leaderboard.js) load `loadTombstonedUids` and leave
 * tombstoned users out, so only a build that started before the tombstone can
 * still write a deleted user into a snapshot.
 *
 * The pure helpers take `db` / `auth` / `FieldValue` / `Timestamp` as
 * arguments so the tests can inject an in-memory Firestore; only the exported
 * Cloud Functions reach for the real Admin SDK, and they do so lazily so
 * requiring this module never needs an initialized app.
 */

const functionsV1 = require("firebase-functions/v1");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const DELETED_USERS = "deleted_users";
const PAGE_LIMIT = 400;
const RECENT_LOGIN_SECONDS = 300;
const TOMBSTONE_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const SWEEP_WINDOW_MS = 3 * 24 * 60 * 60 * 1000;
const SWEEP_RESWEEP_AFTER_MS = 5 * 60 * 60 * 1000;
const SWEEP_TIME_BUDGET_MS = 450 * 1000;
// A purge started by the sweep stops between ranking-entry pages past this
// point (measured from the sweep's start), leaving 40 s of the 540 s timeout.
const SWEEP_PURGE_DEADLINE_MS = 500 * 1000;
// Mirrors PAGE_SIZE in leaderboard.js: page `n` of a snapshot holds ranked
// entries n * 50 … n * 50 + 49 (0-based), with `rank_start` / `rank_end`.
const SNAPSHOT_PAGE_SIZE = 50;
const SNAPSHOT_SCRUB_CONCURRENCY = 8;

// A snapshot build excludes every uid tombstoned when it loads the tombstone
// set, so only a build that loaded it before the tombstone was written can
// still list a deleted user — possibly on pages written after the purge
// deleted the ranking_entries that would point back at them. The builder
// (`_buildSnapshotForScope` in leaderboard.js) stamps `generated_at` as a
// Firestore Timestamp at build start and again when the snapshot turns
// "ready", and a build run lasts at most 540 s, so any such build carries a
// `generated_at` near `deleted_at`: the window is ±20 minutes, with the lower
// bound widened by one full 540 s build for a doc still "processing" that only
// carries its start stamp. Those builds have all finished by
// deleted_at + RACE_WINDOW_AFTER_MS; the sweep only counts a purge that
// started after that as a complete sweep.
const RACE_WINDOW_BEFORE_MS = 20 * 60 * 1000 + 540 * 1000;
const RACE_WINDOW_AFTER_MS = 20 * 60 * 1000;

// Collections purged with a single equality / array-contains query.
const QUERY_PURGES = [
  { collection: "test_sessions", field: "userId", op: "==" },
  { collection: "results", field: "userId", op: "==" },
  { collection: "suspicious_sessions", field: "uid", op: "==" },
  { collection: "ranking_features", field: "uid", op: "==" },
  { collection: "ai_generation_log", field: "userId", op: "==" },
  { collection: "friend_invites", field: "owner_uid", op: "==" },
  { collection: "friendships", field: "participants", op: "array-contains" },
];

// ─────────────────── Helpers ─────────────────────────────────────────────────

function _toMillis(value) {
  if (value === undefined || value === null) return undefined;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  const number = Number(value);
  return Number.isFinite(number) ? number : undefined;
}

function _isUserNotFound(error) {
  return Boolean(error) &&
    (error.code === "auth/user-not-found" || error.errorInfo?.code === "auth/user-not-found");
}

/// Firestore NOT_FOUND: gRPC code 5 from the Admin SDK, or the string form.
function _isNotFound(error) {
  return Boolean(error) && (error.code === 5 || error.code === "not-found");
}

/// Firestore ALREADY_EXISTS: gRPC code 6, or the string form.
function _isAlreadyExists(error) {
  return Boolean(error) && (error.code === 6 || error.code === "already-exists");
}

async function _deleteAuthUser(auth, uid) {
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (!_isUserNotFound(error)) throw error;
  }
}

/// Runs `fn` over `items` with at most `limit` calls in flight.
async function _mapWithConcurrency(items, limit, fn) {
  const results = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await fn(items[index], index);
    }
  });
  await Promise.all(workers);
  return results;
}

/**
 * The uids of every live tombstone, from a single query. Snapshot builds load
 * it once per run and leave these users out of the ranking.
 *
 * Bounded by design: `expire_at` is 30 days after the deletion and the TTL
 * policy removes the tombstone after that (the filter ignores one the TTL
 * hasn't reached yet), so the set is at most 30 days of account deletions,
 * not the user base.
 *
 * @param {number|Date|Timestamp} now
 * @returns {Promise<Set<string>>}
 */
async function loadTombstonedUids(db, now) {
  const snap = await db
    .collection(DELETED_USERS)
    .where("expire_at", ">", new Date(_toMillis(now)))
    .get();
  return new Set(snap.docs.map((doc) => doc.id));
}

/// Drops feature entries whose `uid` is in `tombstonedUids`. Pure; returns
/// `entries` itself when there is nothing to drop.
function excludeTombstonedEntries(entries, tombstonedUids) {
  if (!tombstonedUids || tombstonedUids.size === 0) return entries;
  return entries.filter((entry) => !tombstonedUids.has(entry.uid));
}

async function isDeletedUser(db, uid) {
  if (!uid) return false;
  const doc = await db.collection(DELETED_USERS).doc(uid).get();
  return doc.exists;
}

/**
 * Writes the tombstone for `uid`. Retry-safe: an existing tombstone keeps its
 * original `deleted_at` (the race window and the sweep window are both
 * anchored on it), so only a missing tombstone — or one somehow missing the
 * field — gets a fresh stamp.
 *
 * @returns {number|undefined} the stored `deleted_at` in milliseconds.
 */
async function writeTombstone(db, FieldValue, Timestamp, uid, now) {
  const nowMs = _toMillis(now);
  const ref = db.collection(DELETED_USERS).doc(uid);

  try {
    await ref.create({
      deleted_at: FieldValue.serverTimestamp(),
      expire_at: Timestamp.fromMillis(nowMs + TOMBSTONE_TTL_MS),
    });
  } catch (error) {
    if (!_isAlreadyExists(error)) throw error;

    const existing = await ref.get();
    const data = existing.exists ? existing.data() : undefined;
    if (!data || data.deleted_at === undefined || data.deleted_at === null) {
      await ref.set({
        deleted_at: FieldValue.serverTimestamp(),
        expire_at: Timestamp.fromMillis(nowMs + TOMBSTONE_TTL_MS),
      }, { merge: true });
    } else {
      return _toMillis(data.deleted_at);
    }
  }

  const stored = await ref.get();
  return _toMillis(stored.exists ? stored.data().deleted_at : undefined);
}

/// Deletes every document matched by `query`, one page at a time, until the
/// query comes back empty. `beforeDelete` sees each page before it goes, and
/// `shouldStop`, if given, is asked after each page whether to stop early.
async function _deleteQueryInPages(db, query, beforeDelete, shouldStop) {
  let deleted = 0;
  while (true) {
    const snap = await query.limit(PAGE_LIMIT).get();
    if (snap.empty) break;

    if (beforeDelete) {
      await beforeDelete(snap.docs);
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += snap.size;
    if (shouldStop && shouldStop()) break;
  }
  return deleted;
}

/// `ref.update(data)`, where a document deleted underneath us (cleanupSnapshots
/// removing an old snapshot) counts as done. Returns whether it was written.
async function _updateIgnoringNotFound(ref, data) {
  try {
    await ref.update(data);
    return true;
  } catch (error) {
    if (_isNotFound(error)) return false;
    throw error;
  }
}

/// Transactionally removes entries with `uid === uid` from the array `field`
/// of `ref`. Read, filter and write happen in one transaction, so two purges
/// scrubbing different users from the same document can't lose each other's
/// update. A missing document (before or during the transaction) is success.
///
/// @returns {{existed: boolean, updated: boolean, found: boolean, data: Object|undefined}}
///   `existed` is true if any attempt saw the document; `found` and `data`
///   describe the last attempt's read (`found`: the uid was listed).
async function _scrubArrayField(db, ref, field, uid) {
  let existed = false;
  let found = false;
  let data;
  try {
    const updated = await db.runTransaction(async (transaction) => {
      found = false;
      data = undefined;
      const doc = await transaction.get(ref);
      if (!doc.exists) return false;
      existed = true;
      data = doc.data();

      const items = data[field];
      if (!Array.isArray(items)) return false;
      const kept = items.filter((item) => !item || item.uid !== uid);
      if (kept.length === items.length) return false;
      found = true;

      transaction.update(ref, { [field]: kept });
      return true;
    });
    return { existed, updated, found, data };
  } catch (error) {
    if (_isNotFound(error)) return { existed, updated: false, found: false, data: undefined };
    throw error;
  }
}

/// A usable 1-based rank, or undefined.
function _asRank(value) {
  return Number.isInteger(value) && value >= 1 ? value : undefined;
}

/// The last rank a page was built with: `rank_end`, which a scrub never
/// changes, else the highest rank still listed. Undefined for an empty page
/// without `rank_end`.
function _pageLastRank(data) {
  if (!data) return undefined;
  if (Number.isFinite(data.rank_end)) return data.rank_end;
  const ranks = (Array.isArray(data.entries) ? data.entries : [])
    .map((item) => item && item.rank)
    .filter(Number.isFinite);
  return ranks.length ? Math.max(...ranks) : undefined;
}

/// Removes `uid` from a snapshot's highlights and from every page that lists
/// it. Documents that don't contain the user are left untouched, and
/// documents deleted concurrently are treated as scrubbed.
///
/// With the user's `rank` (from their ranking entry) only the page that rank
/// lands on is read, plus following pages while the user hasn't been found and
/// the page ends at or before that rank. Without one, every page is listed.
async function _scrubSnapshot(db, snapshotId, uid, rank) {
  const snapshotRef = db.collection("leaderboard_snapshots").doc(snapshotId);
  const highlights = await _scrubArrayField(db, snapshotRef, "top_highlights", uid);
  if (!highlights.existed) {
    return 0;
  }

  let updated = highlights.updated ? 1 : 0;

  // One transaction per page rather than one for everything: a single page
  // removed by cleanupSnapshots would otherwise fail the whole write, and a
  // snapshot can have more pages than a transaction should hold.
  const pagesRef = snapshotRef.collection("pages");
  if (_asRank(rank) !== undefined) {
    // Ranks are 1-based and a tie takes the rank of its first position, so
    // the entry at position i has rank <= i + 1: it is never on a page before
    // floor((rank - 1) / SNAPSHOT_PAGE_SIZE), but a tie can push it later.
    for (let index = Math.floor((rank - 1) / SNAPSHOT_PAGE_SIZE); ; index++) {
      const page = await _scrubArrayField(db, pagesRef.doc(`${index}`), "entries", uid);
      if (page.updated) updated++;
      if (!page.existed || page.found) break;
      const lastRank = _pageLastRank(page.data);
      if (lastRank === undefined || lastRank > rank) break;
    }
    return updated;
  }

  const pages = await pagesRef.get();
  for (const page of pages.docs) {
    if (!Array.isArray(page.data().entries)) continue;
    if ((await _scrubArrayField(db, page.ref, "entries", uid)).updated) updated++;
  }

  return updated;
}

/**
 * The part of the purge the callable waits on: every per-user document, but
 * no ranking entries and no snapshot scrubbing. Idempotent.
 *
 * @returns {Object} per-collection counts (numbers only) for logging.
 */
async function quickPurge(db, FieldValue, uid) {
  if (!uid) {
    throw new Error("quickPurge requires a uid.");
  }

  const counts = {};

  // 1. The dirty marker goes first, so aggregateIncremental can't rebuild
  //    ranking features from sessions that are about to be deleted.
  await db.collection("leaderboard_dirty_users").doc(uid).delete();
  counts.leaderboard_dirty_users = 1;

  // 2. Straight query deletes.
  for (const { collection, field, op } of QUERY_PURGES) {
    counts[collection] = await _deleteQueryInPages(
      db,
      db.collection(collection).where(field, op, uid),
    );
  }

  // 3. Per-user documents.
  await db.collection("user_best_scores").doc(uid).delete();
  await db.collection("leaderboard_profiles").doc(uid).delete();
  await db.collection("subscriptions").doc(uid).delete();
  await db.recursiveDelete(db.collection("users").doc(uid));

  // 4. Generated questions are shared content: keep them, drop the owner.
  counts.ai_generated_questions = 0;
  while (true) {
    const snap = await db
      .collection("ai_generated_questions")
      .where("generatedFor", "==", uid)
      .limit(PAGE_LIMIT)
      .get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, { generatedFor: FieldValue.delete() });
    }
    await batch.commit();
    counts.ai_generated_questions += snap.size;
  }

  return counts;
}

/// The race windows around each anchor, sorted and with overlapping windows
/// merged, so two nearby anchors cost one query.
function _raceWindows(anchorsMs) {
  const windows = anchorsMs
    .map((anchor) => ({ lower: anchor - RACE_WINDOW_BEFORE_MS, upper: anchor + RACE_WINDOW_AFTER_MS }))
    .sort((a, b) => a.lower - b.lower);
  const merged = [];
  for (const window of windows) {
    const last = merged[merged.length - 1];
    if (last && window.lower <= last.upper) {
      last.upper = Math.max(last.upper, window.upper);
    } else {
      merged.push({ ...window });
    }
  }
  return merged;
}

/// Scrubs `uid` from every snapshot whose `generated_at` falls inside
/// [lowerMs, upperMs], skipping ids already scrubbed in this run. Stops
/// between query pages when `shouldStop` says so.
async function _scrubSnapshotsInRaceWindow(db, uid, lowerMs, upperMs, alreadyScrubbed, counts, shouldStop) {
  const lower = new Date(lowerMs);
  const upper = new Date(upperMs);

  let cursor = null;
  while (true) {
    let query = db
      .collection("leaderboard_snapshots")
      .where("generated_at", ">=", lower)
      .where("generated_at", "<=", upper)
      .orderBy("generated_at")
      .limit(PAGE_LIMIT);
    if (cursor) query = query.startAfter(cursor);

    const snap = await query.get();
    if (snap.empty) break;
    cursor = snap.docs[snap.docs.length - 1];

    const ids = snap.docs.map((doc) => doc.id).filter((id) => !alreadyScrubbed.has(id));
    for (const id of ids) alreadyScrubbed.add(id);

    const updated = await _mapWithConcurrency(ids, SNAPSHOT_SCRUB_CONCURRENCY, (id) =>
      _scrubSnapshot(db, id, uid));
    counts.window_snapshots_scrubbed += ids.length;
    counts.snapshot_docs_updated += updated.reduce((sum, n) => sum + n, 0);

    if (snap.size < PAGE_LIMIT) break;
    if (shouldStop && shouldStop()) break;
  }
}

/**
 * Removes everything stored for `uid`: quickPurge, then snapshots found via
 * the user's ranking entries (scrubbed before those entries are deleted, so an
 * interrupted run still finds them), then snapshots generated around the
 * deletion time. Idempotent: running it again on a purged user finds nothing
 * and changes nothing.
 *
 * Builds that load the tombstone set after the tombstone was written leave
 * the user out (see `loadTombstonedUids`), so the only builds that can race a
 * purge started before the tombstone, and the `deletedAtMs` window catches
 * them once they have finished.
 *
 * @param {Object} [options]
 * @param {number} [options.deletedAtMs] the tombstone's `deleted_at`; a race
 *   window is centred on it. Defaults to the purge start, for a caller with no
 *   tombstone.
 * @param {number} [options.previousSweepAtMs] the tombstone's previous
 *   `last_swept_at`; a second window is centred on it. Every build that could
 *   have raced that sweep has finished by the time the next one runs.
 * @param {number} [options.deadlineMs] stop between ranking-entry pages (and
 *   between race-window query pages) once `now()` reaches this, and report
 *   `partial: 1`. The remaining work is found again by the next run.
 * @param {Function} [options.now] current time in milliseconds.
 * @returns {Object} per-collection counts (numbers only) for logging, with
 *   `partial` 1 if the deadline cut the run short, else 0.
 */
async function purgeUserData(db, FieldValue, uid, options = {}) {
  if (!uid) {
    throw new Error("purgeUserData requires a uid.");
  }
  const now = options.now || (() => Date.now());
  const deletedAtMs = Number.isFinite(options.deletedAtMs) ? options.deletedAtMs : now();
  const anchorsMs = [deletedAtMs];
  if (Number.isFinite(options.previousSweepAtMs)) anchorsMs.push(options.previousSweepAtMs);

  let partial = false;
  const shouldStop = () => {
    partial = partial || (Number.isFinite(options.deadlineMs) && now() >= options.deadlineMs);
    return partial;
  };

  const counts = await quickPurge(db, FieldValue, uid);

  const scrubbed = new Set();
  counts.snapshot_docs_updated = 0;
  counts.ranking_entries = await _deleteQueryInPages(
    db,
    db.collection("ranking_entries").where("uid", "==", uid),
    async (docs) => {
      const targets = [];
      for (const doc of docs) {
        const { snapshot_id: snapshotId, rank } = doc.data();
        if (!snapshotId || scrubbed.has(snapshotId)) continue;
        scrubbed.add(snapshotId);
        targets.push({ snapshotId, rank });
      }
      const updated = await _mapWithConcurrency(targets, SNAPSHOT_SCRUB_CONCURRENCY, ({ snapshotId, rank }) =>
        _scrubSnapshot(db, snapshotId, uid, rank));
      counts.snapshot_docs_updated += updated.reduce((sum, n) => sum + n, 0);
    },
    shouldStop,
  );
  counts.snapshots_scrubbed = scrubbed.size;

  counts.window_snapshots_scrubbed = 0;
  if (!partial) {
    // `scrubbed` dedupes across the windows and the ranking-entry pass.
    for (const { lower, upper } of _raceWindows(anchorsMs)) {
      await _scrubSnapshotsInRaceWindow(db, uid, lower, upper, scrubbed, counts, shouldStop);
      if (partial) break;
    }
  }

  counts.partial = partial ? 1 : 0;
  return counts;
}

/// True only for an anonymous account that has never linked a credential.
/// A linked guest keeps `sign_in_provider: "anonymous"` on tokens minted from
/// its old refresh token but gains entries in `identities`.
function _isTrueGuest(token) {
  const firebase = token.firebase || {};
  return firebase.sign_in_provider === "anonymous" &&
    Object.keys(firebase.identities || {}).length === 0;
}

/**
 * Builds the `deleteAccount` onCall handler around injected dependencies.
 * `now` returns the current time in milliseconds.
 */
function makeDeleteAccountHandler({ db, auth, FieldValue, Timestamp, now = () => Date.now() }) {
  return async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const uid = request.auth.uid;
    const token = request.auth.token || {};
    const nowMs = now();

    // True guests have nothing to re-authenticate with; everyone else must
    // have signed in within the last five minutes.
    if (!_isTrueGuest(token)) {
      const authTime = token.auth_time;
      if (typeof authTime !== "number" || !Number.isFinite(authTime) ||
          nowMs / 1000 - authTime > RECENT_LOGIN_SECONDS) {
        throw new HttpsError("failed-precondition", "requires-recent-login");
      }
    }

    try {
      await writeTombstone(db, FieldValue, Timestamp, uid, nowMs);
      await _deleteAuthUser(auth, uid);
      const counts = await quickPurge(db, FieldValue, uid);
      console.log("[deleteAccount] quick purge", counts);
      return { deleted: true };
    } catch (error) {
      // The tombstone (if it was written) lets the sweep finish the job.
      console.error("[deleteAccount] failed:", error);
      throw new HttpsError("internal", "Account deletion failed.");
    }
  };
}

/**
 * Finishes and re-purges every user tombstoned within the sweep window.
 *
 * Order: tombstones never attempted go first (oldest deletion first), then the
 * rest by their latest `last_attempt_at` / `last_swept_at` (oldest first), so
 * neither a backlog of re-sweeps nor a tombstone whose purge keeps dying can
 * starve the others of the time budget. `last_attempt_at` is stamped when the
 * sweep starts a tombstone, `last_swept_at` when a complete purge finishes.
 *
 * Skipped: tombstones swept within the last five hours, and tombstones
 * attempted within the last five hours without a sweep since (an attempt is
 * in flight or died recently). No new tombstone is started once the time
 * budget has run out, and a purge that hits its deadline ends the run.
 *
 * `last_swept_at` is only stamped for a complete purge that started at or
 * after deleted_at + RACE_WINDOW_AFTER_MS, when every build that could have
 * raced the deletion has finished. Otherwise the tombstone stays due and a
 * later sweep (the schedule is every six hours) scrubs the deleted_at window
 * again — so the window is always scrubbed at least once after that point.
 *
 * The ordering is done in memory over one query of the 3-day window. That
 * holds every tombstone from the last three days: bounded by three days of
 * deletions (each a document of a few small fields), not by the user base.
 *
 * @returns {{swept: number, skipped: number, failed: number, partial: number, stoppedEarly: boolean}}
 *   `partial` counts purges that ran but were not marked swept.
 */
async function sweepRecentTombstones({ db, auth, FieldValue, Timestamp, now = () => Date.now() }) {
  const startedAt = now();
  const cutoff = Timestamp.fromMillis(startedAt - SWEEP_WINDOW_MS);
  const snap = await db
    .collection(DELETED_USERS)
    .where("deleted_at", ">=", cutoff)
    .orderBy("deleted_at", "asc")
    .get();

  const queue = snap.docs.map((doc, index) => {
    const data = doc.data() || {};
    const lastSweptMs = _toMillis(data.last_swept_at);
    const lastAttemptMs = _toMillis(data.last_attempt_at);
    const touched = [lastSweptMs, lastAttemptMs].filter((ms) => ms !== undefined);
    return {
      doc,
      index,
      data,
      lastSweptMs,
      lastAttemptMs,
      lastTouchedMs: touched.length ? Math.max(...touched) : undefined,
    };
  });
  queue.sort((a, b) => {
    const aNever = a.lastTouchedMs === undefined;
    const bNever = b.lastTouchedMs === undefined;
    if (aNever !== bNever) return aNever ? -1 : 1;
    if (!aNever && a.lastTouchedMs !== b.lastTouchedMs) return a.lastTouchedMs - b.lastTouchedMs;
    return a.index - b.index; // the query's deleted_at order
  });

  const result = { swept: 0, skipped: 0, failed: 0, partial: 0, stoppedEarly: false };
  for (const { doc, data, lastSweptMs, lastAttemptMs } of queue) {
    const nowMs = now();
    const sweptRecently = lastSweptMs !== undefined && nowMs - lastSweptMs < SWEEP_RESWEEP_AFTER_MS;
    const attemptedRecently = lastAttemptMs !== undefined &&
      nowMs - lastAttemptMs < SWEEP_RESWEEP_AFTER_MS &&
      (lastSweptMs === undefined || lastSweptMs < lastAttemptMs);
    if (sweptRecently || attemptedRecently) {
      result.skipped++;
      continue;
    }

    if (nowMs - startedAt >= SWEEP_TIME_BUDGET_MS) {
      result.stoppedEarly = true;
      break;
    }

    const uid = doc.id;
    const deletedAtMs = _toMillis(data.deleted_at);
    try {
      // update, not set: a tombstone expired by TTL mid-run must not come
      // back as a document without deleted_at.
      await _updateIgnoringNotFound(doc.ref, { last_attempt_at: Timestamp.fromMillis(now()) });
      const purgeStartedAtMs = now();
      await _deleteAuthUser(auth, uid);
      const counts = await purgeUserData(db, FieldValue, uid, {
        deletedAtMs,
        previousSweepAtMs: lastSweptMs,
        deadlineMs: startedAt + SWEEP_PURGE_DEADLINE_MS,
        now,
      });
      console.log("[sweepDeletedUsers] purged", counts);

      if (counts.partial) {
        result.partial++;
        result.stoppedEarly = true;
        break;
      }
      // Assertion: a sweep marks a tombstone swept only after scrubbing its
      // deleted_at window at or after deleted_at + RACE_WINDOW_AFTER_MS (the
      // window query runs after purgeStartedAtMs). A sweep is normally hours
      // later, but a tombstone written just before a scheduled run is not.
      if (Number.isFinite(deletedAtMs) && purgeStartedAtMs < deletedAtMs + RACE_WINDOW_AFTER_MS) {
        result.partial++;
        continue;
      }

      await _updateIgnoringNotFound(doc.ref, { last_swept_at: Timestamp.fromMillis(now()) });
      result.swept++;
    } catch (error) {
      result.failed++;
      console.error("[sweepDeletedUsers] sweep failed:", error);
    }
  }
  return result;
}

// ─────────────────── Cloud Functions ─────────────────────────────────────────

function _admin() {
  const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
  const { getAuth } = require("firebase-admin/auth");
  return { db: getFirestore(), auth: getAuth(), FieldValue, Timestamp };
}

exports.deleteAccount = onCall(
  { region: "us-central1", maxInstances: 20, timeoutSeconds: 540 },
  (request) => makeDeleteAccountHandler(_admin())(request),
);

exports.onAuthUserDeleted = functionsV1
  .region("us-central1")
  .runWith({ timeoutSeconds: 540 })
  .auth.user()
  .onDelete(async (user) => {
    const { db, FieldValue, Timestamp } = _admin();
    const deletedAtMs = await writeTombstone(db, FieldValue, Timestamp, user.uid, Date.now());
    const counts = await purgeUserData(db, FieldValue, user.uid, { deletedAtMs });
    console.log("[onAuthUserDeleted] purged", counts);
  });

exports.sweepDeletedUsers = onSchedule(
  {
    region: "us-central1",
    schedule: "every 6 hours",
    timeZone: "UTC",
    maxInstances: 1,
    timeoutSeconds: 540,
  },
  async () => {
    const result = await sweepRecentTombstones(_admin());
    console.log("[sweepDeletedUsers] done", result);
  },
);

module.exports.purgeUserData = purgeUserData;
module.exports.quickPurge = quickPurge;
module.exports.makeDeleteAccountHandler = makeDeleteAccountHandler;
module.exports.writeTombstone = writeTombstone;
module.exports.isDeletedUser = isDeletedUser;
module.exports.loadTombstonedUids = loadTombstonedUids;
module.exports.excludeTombstonedEntries = excludeTombstonedEntries;
module.exports.sweepRecentTombstones = sweepRecentTombstones;
module.exports.RACE_WINDOW_BEFORE_MS = RACE_WINDOW_BEFORE_MS;
module.exports.RACE_WINDOW_AFTER_MS = RACE_WINDOW_AFTER_MS;
module.exports.SNAPSHOT_PAGE_SIZE = SNAPSHOT_PAGE_SIZE;
