const { test, describe } = require("node:test");
const assert = require("node:assert/strict");

const { FakeFirestore, FakeFieldValue, FakeTimestamp } = require("./fakeFirestore");
const {
  purgeUserData,
  quickPurge,
  makeDeleteAccountHandler,
  writeTombstone,
  isDeletedUser,
  sweepRecentTombstones,
  loadTombstonedUids,
  excludeTombstonedEntries,
  SNAPSHOT_PAGE_SIZE,
  RACE_WINDOW_BEFORE_MS,
  RACE_WINDOW_AFTER_MS,
} = require("../accountDeletion");

// The module logs purge counts; keep test output readable.
console.log = () => {};

const A = "user_a";
const B = "user_b";
const NOW_MS = Date.UTC(2026, 8, 16, 12, 0, 0);
const NOW_S = NOW_MS / 1000;

function entry(uid, rank) {
  return { uid, display_name: uid, rank, score: 100 - rank };
}

/// Seeds a world with data for A and B across every purged collection.
function seedWorld(db) {
  for (const uid of [A, B]) {
    db.seed(`leaderboard_dirty_users/${uid}`, { uid });
    db.seed(`test_sessions/s_${uid}_1`, { userId: uid, testType: "iq" });
    db.seed(`test_sessions/s_${uid}_2`, { userId: uid, testType: "eq" });
    db.seed(`results/s_${uid}_1`, { userId: uid, iqScore: 110 });
    db.seed(`suspicious_sessions/s_${uid}_1`, { uid, risk_score: 40 });
    db.seed(`ranking_features/iq_weekly_global_all_${uid}`, { uid, rank_score: 1 });
    db.seed(`ai_generation_log/log_${uid}`, { userId: uid });
    db.seed(`friend_invites/code_${uid}`, { owner_uid: uid });
    db.seed(`user_best_scores/${uid}`, { uid });
    db.seed(`leaderboard_profiles/${uid}`, { display_name: uid });
    db.seed(`subscriptions/${uid}`, { active: true });
    db.seed(`users/${uid}`, { email: `${uid}@example.com` });
    db.seed(`users/${uid}/daily_insights/2026-09-16`, { text: "hi" });
    db.seed(`users/${uid}/preferences/main`, { haptics: true });
    db.seed(`ai_generated_questions/q_${uid}`, { prompt: "?", generatedFor: uid });
  }

  // A is the *second* participant here, the receiver.
  db.seed("friendships/f_b_a", { participants: [B, A], sender_uid: B, receiver_uid: A });
  db.seed("friendships/f_b_c", { participants: [B, "user_c"], sender_uid: B, receiver_uid: "user_c" });

  // A snapshot both users rank in, across two of three pages.
  const snap = "iq_global_all_weekly_2026-09-16";
  db.seed(`leaderboard_snapshots/${snap}`, {
    status: "ready",
    top_highlights: [entry(B, 1), entry(A, 2)],
  });
  db.seed(`leaderboard_snapshots/${snap}/pages/0`, { page: 0, entries: [entry(B, 1), entry(A, 2)] });
  db.seed(`leaderboard_snapshots/${snap}/pages/1`, { page: 1, entries: [entry("user_c", 3)] });
  db.seed(`leaderboard_snapshots/${snap}/pages/2`, { page: 2, entries: [entry(B, 4)] });
  db.seed(`ranking_entries/${snap}_${A}`, { snapshot_id: snap, uid: A });
  db.seed(`ranking_entries/${snap}_${B}`, { snapshot_id: snap, uid: B });

  // A second snapshot where A is not a highlight: highlights must not be rewritten.
  const snap2 = "eq_global_all_weekly_2026-09-16";
  db.seed(`leaderboard_snapshots/${snap2}`, { status: "ready", top_highlights: [entry(B, 1)] });
  db.seed(`leaderboard_snapshots/${snap2}/pages/0`, { page: 0, entries: [entry(B, 1)] });
  db.seed(`leaderboard_snapshots/${snap2}/pages/1`, { page: 1, entries: [entry(A, 51)] });
  db.seed(`ranking_entries/${snap2}_${A}`, { snapshot_id: snap2, uid: A });

  // An entry pointing at a snapshot that cleanup already removed.
  db.seed(`ranking_entries/gone_${A}`, { snapshot_id: "gone", uid: A });

  return { snap, snap2 };
}

describe("purgeUserData", () => {
  test("purges every collection for A and leaves B untouched", async () => {
    const db = new FakeFirestore();
    const { snap, snap2 } = seedWorld(db);
    const before = new Map(db.paths().map((path) => [path, db.read(path)]));

    const counts = await purgeUserData(db, FakeFieldValue, A);

    const aPaths = [
      `leaderboard_dirty_users/${A}`,
      `test_sessions/s_${A}_1`,
      `test_sessions/s_${A}_2`,
      `results/s_${A}_1`,
      `suspicious_sessions/s_${A}_1`,
      `ranking_features/iq_weekly_global_all_${A}`,
      `ai_generation_log/log_${A}`,
      `friend_invites/code_${A}`,
      "friendships/f_b_a",
      `ranking_entries/${snap}_${A}`,
      `ranking_entries/${snap2}_${A}`,
      `ranking_entries/gone_${A}`,
      `user_best_scores/${A}`,
      `leaderboard_profiles/${A}`,
      `subscriptions/${A}`,
      `users/${A}`,
      `users/${A}/daily_insights/2026-09-16`,
      `users/${A}/preferences/main`,
    ];
    for (const path of aPaths) {
      assert.equal(db.has(path), false, `${path} should be deleted`);
    }

    // Everything of B's survives byte for byte, except the shared snapshot
    // documents that also listed A.
    const scrubbedPaths = new Set([
      `leaderboard_snapshots/${snap}`,
      `leaderboard_snapshots/${snap}/pages/0`,
      `leaderboard_snapshots/${snap2}/pages/1`,
      `ai_generated_questions/q_${A}`,
    ]);
    for (const [path, data] of before) {
      if (aPaths.includes(path) || scrubbedPaths.has(path)) continue;
      assert.deepEqual(db.read(path), data, `${path} should be unchanged`);
    }

    assert.equal(counts.test_sessions, 2);
    assert.equal(counts.friendships, 1);
    assert.equal(counts.ranking_entries, 3);
    assert.equal(counts.snapshots_scrubbed, 3);
    for (const value of Object.values(counts)) {
      assert.equal(typeof value, "number");
    }
  });

  test("scrubs A from snapshot highlights and pages, keeps B, skips untouched pages", async () => {
    const db = new FakeFirestore();
    const { snap, snap2 } = seedWorld(db);

    await purgeUserData(db, FakeFieldValue, A);

    assert.deepEqual(db.read(`leaderboard_snapshots/${snap}`).top_highlights, [entry(B, 1)]);
    assert.deepEqual(db.read(`leaderboard_snapshots/${snap}/pages/0`).entries, [entry(B, 1)]);
    assert.deepEqual(db.read(`leaderboard_snapshots/${snap}/pages/1`).entries, [entry("user_c", 3)]);
    assert.deepEqual(db.read(`leaderboard_snapshots/${snap}/pages/2`).entries, [entry(B, 4)]);
    assert.deepEqual(db.read(`leaderboard_snapshots/${snap2}/pages/1`).entries, []);

    // Documents that never listed A are not rewritten.
    assert.equal(db.writesTo(`leaderboard_snapshots/${snap}/pages/1`).length, 0);
    assert.equal(db.writesTo(`leaderboard_snapshots/${snap}/pages/2`).length, 0);
    assert.equal(db.writesTo(`leaderboard_snapshots/${snap2}`).length, 0);
    assert.equal(db.writesTo(`leaderboard_snapshots/${snap2}/pages/0`).length, 0);
    assert.equal(db.has(`ranking_entries/${snap}_${B}`), true);
    assert.equal(db.has("leaderboard_snapshots/gone"), false);
  });

  test("keeps AI questions but drops generatedFor", async () => {
    const db = new FakeFirestore();
    seedWorld(db);

    await purgeUserData(db, FakeFieldValue, A);

    assert.deepEqual(db.read(`ai_generated_questions/q_${A}`), { prompt: "?" });
    assert.deepEqual(db.read(`ai_generated_questions/q_${B}`), { prompt: "?", generatedFor: B });
  });

  test("removes users/{uid} subcollections", async () => {
    const db = new FakeFirestore();
    seedWorld(db);

    await purgeUserData(db, FakeFieldValue, A);

    assert.deepEqual(db.paths().filter((path) => path.startsWith(`users/${A}`)), []);
    assert.equal(db.has(`users/${B}/daily_insights/2026-09-16`), true);
    assert.equal(db.has(`users/${B}/preferences/main`), true);
  });

  test("deletes the dirty marker before touching sessions", async () => {
    const db = new FakeFirestore();
    seedWorld(db);

    await purgeUserData(db, FakeFieldValue, A);

    const markerIndex = db.log.findIndex(
      (e) => e.op === "delete" && e.path === `leaderboard_dirty_users/${A}`,
    );
    const firstSessionTouch = db.log.findIndex((e) => e.path.startsWith("test_sessions"));
    assert.ok(markerIndex >= 0, "dirty marker delete was logged");
    assert.ok(firstSessionTouch >= 0, "sessions were queried");
    assert.ok(markerIndex < firstSessionTouch, "dirty marker goes before sessions");
    assert.equal(markerIndex, 0, "dirty marker is the very first operation");
  });

  test("paginates past 400 documents without oversized batches", async () => {
    const db = new FakeFirestore();
    for (let i = 0; i < 1001; i++) {
      db.seed(`test_sessions/bulk_${String(i).padStart(4, "0")}`, { userId: A });
    }
    for (let i = 0; i < 850; i++) {
      db.seed(`ai_generated_questions/bulk_${String(i).padStart(4, "0")}`, { generatedFor: A });
    }
    db.seed("test_sessions/keep_b", { userId: B });

    const counts = await purgeUserData(db, FakeFieldValue, A);

    assert.equal(counts.test_sessions, 1001);
    assert.equal(counts.ai_generated_questions, 850);
    assert.deepEqual(db.paths().filter((p) => p.startsWith("test_sessions/")), ["test_sessions/keep_b"]);
    assert.ok(db.batchSizes.every((size) => size <= 400), "every batch holds at most 400 ops");

    const sessionQueries = db.log.filter((e) => e.op === "query" && e.path === "test_sessions");
    assert.equal(sessionQueries.length, 4, "three full pages plus the empty one");
    assert.ok(sessionQueries.every((q) => q.limit === 400));
  });

  test("is idempotent", async () => {
    const db = new FakeFirestore();
    seedWorld(db);

    await purgeUserData(db, FakeFieldValue, A);
    const afterFirst = new Map(db.paths().map((path) => [path, db.read(path)]));
    const logLength = db.log.length;

    const counts = await purgeUserData(db, FakeFieldValue, A);

    assert.deepEqual(new Map(db.paths().map((path) => [path, db.read(path)])), afterFirst);
    const writes = db.log
      .slice(logLength)
      .filter((e) => ["set", "update"].includes(e.op));
    assert.deepEqual(writes, [], "second run rewrites nothing");
    assert.equal(counts.test_sessions, 0);
    assert.equal(counts.ranking_entries, 0);
    assert.equal(counts.ai_generated_questions, 0);
  });
});

describe("snapshot scrub hardening", () => {
  test("two concurrent purges on the same snapshot documents lose neither update", async () => {
    const db = new FakeFirestore();
    const snap = "shared";
    const snapPath = `leaderboard_snapshots/${snap}`;
    const pagePath = `${snapPath}/pages/0`;
    db.seed(snapPath, { top_highlights: [entry(A, 1), entry(B, 2), entry("user_c", 3)] });
    db.seed(pagePath, { page: 0, entries: [entry(A, 1), entry(B, 2), entry("user_c", 3)] });
    db.seed(`ranking_entries/${snap}_${A}`, { snapshot_id: snap, uid: A });
    db.seed(`ranking_entries/${snap}_${B}`, { snapshot_id: snap, uid: B });

    // Hold the first read of each shared document until both purges have
    // made it, so both read the same original before either writes.
    const waiting = new Map([[snapPath, []], [pagePath, []]]);
    const DocRef = db.doc("x").constructor;
    const get = DocRef.prototype.get;
    DocRef.prototype.get = async function () {
      const queue = waiting.get(this.path);
      if (queue) {
        await new Promise((resolve) => {
          queue.push(resolve);
          if (queue.length === 2) {
            waiting.delete(this.path);
            for (const release of queue) release();
          }
        });
      }
      return get.call(this);
    };
    try {
      await Promise.all([
        purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS }),
        purgeUserData(db, FakeFieldValue, B, { now: () => NOW_MS }),
      ]);
    } finally {
      DocRef.prototype.get = get;
    }

    assert.equal(waiting.size, 0, "both purges read both documents concurrently");
    assert.ok(db.transactionRetries >= 2, `conflicting commits were retried (${db.transactionRetries})`);
    assert.deepEqual(db.read(snapPath).top_highlights, [entry("user_c", 3)]);
    assert.deepEqual(db.read(pagePath).entries, [entry("user_c", 3)]);
  });

  test("NOT_FOUND on a page update is tolerated and the purge completes", async () => {
    const db = new FakeFirestore();
    const { snap, snap2 } = seedWorld(db);

    // cleanupSnapshots removes page 0 between the purge reading it and writing it.
    const pagePath = `leaderboard_snapshots/${snap}/pages/0`;
    let raced = false;
    db.beforeWrite = ({ op, path }) => {
      if (op === "update" && path === pagePath && !raced) {
        raced = true;
        db._docs.delete(pagePath);
      }
    };

    const counts = await purgeUserData(db, FakeFieldValue, A);

    assert.equal(raced, true, "the page update was attempted");
    assert.equal(db.has(pagePath), false, "a NOT_FOUND update must not recreate the page");
    assert.deepEqual(db.read(`leaderboard_snapshots/${snap2}/pages/1`).entries, []);
    assert.equal(counts.ranking_entries, 3);
    assert.equal(db.has(`ranking_entries/${snap}_${A}`), false);
  });

  test("NOT_FOUND on the snapshot highlights update is tolerated", async () => {
    const db = new FakeFirestore();
    const { snap } = seedWorld(db);

    const snapPath = `leaderboard_snapshots/${snap}`;
    db.beforeWrite = ({ op, path }) => {
      if (op === "update" && path === snapPath) db._docs.delete(snapPath);
    };

    await purgeUserData(db, FakeFieldValue, A);
    assert.equal(db.has(snapPath), false);
    assert.deepEqual(db.read(`${snapPath}/pages/0`).entries, [entry(B, 1)]);
  });

  test("errors other than NOT_FOUND still fail the purge", async () => {
    const db = new FakeFirestore();
    const { snap } = seedWorld(db);
    db.beforeWrite = ({ op, path }) => {
      if (op === "update" && path === `leaderboard_snapshots/${snap}/pages/0`) {
        throw Object.assign(new Error("unavailable"), { code: 14 });
      }
    };
    await assert.rejects(purgeUserData(db, FakeFieldValue, A), { code: 14 });
    // The entry is still there, so the next run finds the snapshot again.
    assert.equal(db.has(`ranking_entries/${snap}_${A}`), true);
  });

  test("scrubs snapshots with bounded concurrency", async () => {
    const db = new FakeFirestore();
    for (let i = 0; i < 20; i++) {
      const id = `snap_${String(i).padStart(2, "0")}`;
      db.seed(`leaderboard_snapshots/${id}`, { top_highlights: [entry(A, 1)] });
      db.seed(`ranking_entries/${id}_${A}`, { snapshot_id: id, uid: A });
    }

    let inFlight = 0;
    let peak = 0;
    const get = db.doc("x").constructor.prototype.get;
    db.doc("x").constructor.prototype.get = async function () {
      if (!this.path.startsWith("leaderboard_snapshots/")) return get.call(this);
      inFlight++;
      peak = Math.max(peak, inFlight);
      await new Promise((resolve) => setImmediate(resolve));
      try {
        return await get.call(this);
      } finally {
        inFlight--;
      }
    };
    try {
      const counts = await purgeUserData(db, FakeFieldValue, A);
      assert.equal(counts.snapshots_scrubbed, 20);
    } finally {
      db.doc("x").constructor.prototype.get = get;
    }
    assert.ok(peak > 1, `scrubs run in parallel (peak ${peak})`);
    assert.ok(peak <= 8, `at most 8 scrubs in flight (peak ${peak})`);
    for (let i = 0; i < 20; i++) {
      const id = `snap_${String(i).padStart(2, "0")}`;
      assert.deepEqual(db.read(`leaderboard_snapshots/${id}`).top_highlights, []);
    }
  });
});

describe("race-window snapshot scrub", () => {
  const DELETED_AT = NOW_MS;

  function seedRace(db) {
    const at = (ms) => FakeTimestamp.fromMillis(ms);
    const snapshot = (id, generatedAtMs) => {
      db.seed(`leaderboard_snapshots/${id}`, {
        status: "ready",
        generated_at: at(generatedAtMs),
        top_highlights: [entry(A, 1), entry(B, 2)],
      });
      db.seed(`leaderboard_snapshots/${id}/pages/0`, { page: 0, entries: [entry(A, 1), entry(B, 2)] });
    };
    // Built from features read before the purge; its ranking_entries for A
    // were deleted (or never found), so only the window can reach it.
    snapshot("inside_after", DELETED_AT + 5 * 60 * 1000);
    // Still "processing": carries only the build-start stamp from ~9 minutes earlier.
    snapshot("inside_build_start", DELETED_AT - RACE_WINDOW_BEFORE_MS + 1000);
    snapshot("edge_upper", DELETED_AT + RACE_WINDOW_AFTER_MS);
    snapshot("outside_before", DELETED_AT - RACE_WINDOW_BEFORE_MS - 1000);
    snapshot("outside_after", DELETED_AT + RACE_WINDOW_AFTER_MS + 1000);
    // No generated_at at all: a range query can't match it.
    db.seed("leaderboard_snapshots/no_stamp", { top_highlights: [entry(A, 1)] });
  }

  test("builder window constants cover ±20 minutes plus one 540 s build", () => {
    assert.equal(RACE_WINDOW_AFTER_MS, 20 * 60 * 1000);
    assert.equal(RACE_WINDOW_BEFORE_MS, 20 * 60 * 1000 + 540 * 1000);
  });

  test("removes A from snapshots generated inside the window with no ranking_entries", async () => {
    const db = new FakeFirestore();
    seedRace(db);

    const counts = await purgeUserData(db, FakeFieldValue, A, { deletedAtMs: DELETED_AT, now: () => DELETED_AT });

    for (const id of ["inside_after", "inside_build_start", "edge_upper"]) {
      assert.deepEqual(db.read(`leaderboard_snapshots/${id}`).top_highlights, [entry(B, 2)], id);
      assert.deepEqual(db.read(`leaderboard_snapshots/${id}/pages/0`).entries, [entry(B, 2)], id);
    }
    assert.equal(counts.ranking_entries, 0);
    assert.equal(counts.window_snapshots_scrubbed, 3);

    for (const id of ["outside_before", "outside_after", "no_stamp"]) {
      const touched = db.log.filter((e) =>
        (e.path === `leaderboard_snapshots/${id}` || e.path.startsWith(`leaderboard_snapshots/${id}/`)) &&
        e.op !== "query");
      assert.deepEqual(touched, [], `${id} is neither read nor written`);
      assert.deepEqual(db.read(`leaderboard_snapshots/${id}`).top_highlights[0], entry(A, 1));
    }
    const pageQueries = db.log.filter((e) => e.op === "query" && /outside|no_stamp/.test(e.path));
    assert.deepEqual(pageQueries, [], "pages of snapshots outside the window are not listed");
  });

  test("defaults the window to now when no deletedAt is passed", async () => {
    const db = new FakeFirestore();
    seedRace(db);
    await purgeUserData(db, FakeFieldValue, A, { now: () => DELETED_AT });
    assert.deepEqual(db.read("leaderboard_snapshots/inside_after/pages/0").entries, [entry(B, 2)]);
    assert.equal(db.read("leaderboard_snapshots/outside_after/pages/0").entries.length, 2);
  });

  test("a snapshot found via ranking_entries is not scrubbed twice by the window", async () => {
    const db = new FakeFirestore();
    seedRace(db);
    db.seed(`ranking_entries/inside_after_${A}`, { snapshot_id: "inside_after", uid: A });

    const counts = await purgeUserData(db, FakeFieldValue, A, { deletedAtMs: DELETED_AT, now: () => DELETED_AT });

    assert.equal(counts.snapshots_scrubbed, 1);
    assert.equal(counts.window_snapshots_scrubbed, 2);
    const gets = db.log.filter((e) => e.op === "get" && e.path === "leaderboard_snapshots/inside_after");
    assert.equal(gets.length, 1);
  });

  test("does not scrub a window around the purge start", async () => {
    const db = new FakeFirestore();
    const deletedAt = NOW_MS - 6 * 60 * 60 * 1000;
    const seed = (id, generatedAtMs) => {
      db.seed(`leaderboard_snapshots/${id}`, {
        generated_at: FakeTimestamp.fromMillis(generatedAtMs),
        top_highlights: [entry(A, 1), entry(B, 2)],
      });
      db.seed(`leaderboard_snapshots/${id}/pages/0`, { page: 0, entries: [entry(A, 1), entry(B, 2)] });
    };
    // A build started now loaded the tombstone set and excludes A, so a
    // snapshot near the purge start is outside every window.
    seed("at_purge", NOW_MS);
    seed("at_deletion", deletedAt);

    const counts = await purgeUserData(db, FakeFieldValue, A, { deletedAtMs: deletedAt, now: () => NOW_MS });

    assert.deepEqual(db.read("leaderboard_snapshots/at_deletion/pages/0").entries, [entry(B, 2)]);
    assert.equal(db.read("leaderboard_snapshots/at_purge/pages/0").entries.length, 2);
    assert.equal(counts.window_snapshots_scrubbed, 1);
    assert.equal(counts.partial, 0);
  });

  test("scrubs a window around previousSweepAtMs", async () => {
    const db = new FakeFirestore();
    const deletedAt = NOW_MS - 30 * 60 * 60 * 1000;
    const previousSweep = NOW_MS - 10 * 60 * 60 * 1000;
    db.seed("leaderboard_snapshots/near_previous_sweep", {
      generated_at: FakeTimestamp.fromMillis(previousSweep + 2 * 60 * 1000),
      top_highlights: [entry(A, 1)],
    });
    db.seed("leaderboard_snapshots/between", {
      generated_at: FakeTimestamp.fromMillis(previousSweep - 5 * 60 * 60 * 1000),
      top_highlights: [entry(A, 1)],
    });

    const counts = await purgeUserData(db, FakeFieldValue, A, {
      deletedAtMs: deletedAt,
      previousSweepAtMs: previousSweep,
      now: () => NOW_MS,
    });

    assert.deepEqual(db.read("leaderboard_snapshots/near_previous_sweep").top_highlights, []);
    assert.equal(db.read("leaderboard_snapshots/between").top_highlights.length, 1);
    assert.equal(db.log.filter((e) => e.op === "query" && e.path === "leaderboard_snapshots").length, 2);
    assert.equal(counts.window_snapshots_scrubbed, 1);
  });

  test("overlapping windows are queried once and a snapshot is scrubbed once", async () => {
    const db = new FakeFirestore();
    seedRace(db);
    db.seed(`ranking_entries/edge_upper_${A}`, { snapshot_id: "edge_upper", uid: A });

    // The previous sweep was 10 minutes after the deletion: the two windows overlap.
    const counts = await purgeUserData(db, FakeFieldValue, A, {
      deletedAtMs: DELETED_AT,
      previousSweepAtMs: DELETED_AT + 10 * 60 * 1000,
      now: () => DELETED_AT + 6 * 60 * 60 * 1000,
    });

    const windowQueries = db.log.filter((e) => e.op === "query" && e.path === "leaderboard_snapshots");
    assert.equal(windowQueries.length, 1);
    assert.equal(counts.snapshots_scrubbed, 1);
    // outside_after (+20 min + 1 s) now falls inside the previous-sweep window.
    assert.equal(counts.window_snapshots_scrubbed, 3);
    for (const id of ["inside_after", "inside_build_start", "edge_upper", "outside_after"]) {
      const gets = db.log.filter((e) => e.op === "get" && e.path === `leaderboard_snapshots/${id}`);
      assert.equal(gets.length, 1, id);
      assert.deepEqual(db.read(`leaderboard_snapshots/${id}/pages/0`).entries, [entry(B, 2)], id);
    }
  });

  test("pages through more than 400 snapshots in the window", async () => {
    const db = new FakeFirestore();
    for (let i = 0; i < 405; i++) {
      const id = `w_${String(i).padStart(3, "0")}`;
      // Many share a timestamp, so the cursor must break ties by document.
      db.seed(`leaderboard_snapshots/${id}`, {
        generated_at: FakeTimestamp.fromMillis(DELETED_AT + (i % 3) * 1000),
        top_highlights: [entry(A, 1)],
      });
    }
    const counts = await purgeUserData(db, FakeFieldValue, A, { deletedAtMs: DELETED_AT, now: () => DELETED_AT });
    assert.equal(counts.window_snapshots_scrubbed, 405);
    for (let i = 0; i < 405; i++) {
      assert.deepEqual(db.read(`leaderboard_snapshots/w_${String(i).padStart(3, "0")}`).top_highlights, []);
    }
  });
});

describe("ranking-entry scrub with a known rank", () => {
  /// A snapshot with `pageCount` pages of 50, ranks 1..n with no ties unless
  /// `rankAt` says otherwise, and A placed at `position` (0-based).
  function seedRanked(db, id, { pageCount, position, rankAt = (i) => i + 1, withRankEnd = true, listA = true }) {
    const all = [];
    for (let i = 0; i < pageCount * SNAPSHOT_PAGE_SIZE; i++) {
      const uid = i === position ? A : `other_${i}`;
      all.push(entry(uid, rankAt(i)));
    }
    db.seed(`leaderboard_snapshots/${id}`, { top_highlights: all.slice(0, 3) });
    for (let page = 0; page < pageCount; page++) {
      let entries = all.slice(page * SNAPSHOT_PAGE_SIZE, (page + 1) * SNAPSHOT_PAGE_SIZE);
      const doc = { page, rank_start: entries[0].rank, rank_end: entries[entries.length - 1].rank };
      if (!withRankEnd) delete doc.rank_end;
      if (!listA) entries = entries.filter((e) => e.uid !== A);
      db.seed(`leaderboard_snapshots/${id}/pages/${page}`, { ...doc, entries });
    }
    db.seed(`ranking_entries/${id}_${A}`, { snapshot_id: id, uid: A, rank: rankAt(position) });
  }

  function pageReads(db, id) {
    return db.log
      .filter((e) => e.path.startsWith(`leaderboard_snapshots/${id}/pages`) && ["get", "query"].includes(e.op))
      .map((e) => (e.op === "query" ? "list" : e.path.split("/").pop()));
  }

  test("mirrors PAGE_SIZE in leaderboard.js", () => {
    const source = require("fs").readFileSync(require("path").join(__dirname, "../leaderboard.js"), "utf8");
    assert.match(source, new RegExp(`^const PAGE_SIZE = ${SNAPSHOT_PAGE_SIZE};$`, "m"));
  });

  test("reads only the page the rank lands on", async () => {
    const db = new FakeFirestore();
    seedRanked(db, "s", { pageCount: 5, position: 119 });

    const counts = await purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS });

    assert.deepEqual(pageReads(db, "s"), ["2"]);
    assert.equal(db.read("leaderboard_snapshots/s/pages/2").entries.some((e) => e.uid === A), false);
    assert.equal(db.read("leaderboard_snapshots/s/pages/2").entries.length, 49);
    assert.equal(counts.snapshot_docs_updated, 1);
  });

  test("follows a tie onto later pages and stops at the page that lists A", async () => {
    const db = new FakeFirestore();
    // Positions 80..179 all tie at rank 81; A is at position 160 (page 3).
    const rankAt = (i) => (i >= 80 && i < 180 ? 81 : i + 1);
    seedRanked(db, "s", { pageCount: 5, position: 160, rankAt });

    await purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS });

    assert.deepEqual(pageReads(db, "s"), ["1", "2", "3"]);
    assert.equal(db.read("leaderboard_snapshots/s/pages/3").entries.some((e) => e.uid === A), false);
  });

  test("stops once a page ends past the rank, even if A is not listed", async () => {
    const db = new FakeFirestore();
    seedRanked(db, "s", { pageCount: 5, position: 119, listA: false });

    await purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS });
    assert.deepEqual(pageReads(db, "s"), ["2"]);
    assert.equal(db.writesTo("leaderboard_snapshots/s/pages/2").length, 0);
  });

  test("uses the highest listed rank when a page has no rank_end", async () => {
    const db = new FakeFirestore();
    const rankAt = (i) => (i >= 80 && i < 180 ? 81 : i + 1);
    seedRanked(db, "s", { pageCount: 5, position: 160, rankAt, withRankEnd: false });

    await purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS });
    assert.deepEqual(pageReads(db, "s"), ["1", "2", "3"]);
  });

  test("stops at a missing page", async () => {
    const db = new FakeFirestore();
    // Every page ties at rank 1 and A's page was removed by cleanup.
    seedRanked(db, "s", { pageCount: 3, position: 149, rankAt: () => 1 });
    db._docs.delete("leaderboard_snapshots/s/pages/2");

    await purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS });
    assert.deepEqual(pageReads(db, "s"), ["0", "1", "2"]);
  });

  test("lists every page when the entry carries no rank", async () => {
    const db = new FakeFirestore();
    seedRanked(db, "s", { pageCount: 3, position: 60 });
    db.seed(`ranking_entries/s_${A}`, { snapshot_id: "s", uid: A });

    await purgeUserData(db, FakeFieldValue, A, { now: () => NOW_MS });
    assert.deepEqual(pageReads(db, "s"), ["list", "0", "1", "2"]);
    assert.equal(db.read("leaderboard_snapshots/s/pages/1").entries.some((e) => e.uid === A), false);
  });
});

describe("purge deadline", () => {
  function seedEntries(db, count) {
    for (let i = 0; i < count; i++) {
      db.seed(`ranking_entries/s${String(i).padStart(3, "0")}_${A}`, { snapshot_id: `s${i}`, uid: A });
    }
    db.seed("leaderboard_snapshots/in_window", {
      generated_at: FakeTimestamp.fromMillis(NOW_MS),
      top_highlights: [entry(A, 1)],
    });
  }

  test("stops between ranking-entry pages past the deadline and reports partial", async () => {
    const db = new FakeFirestore();
    seedEntries(db, 401);
    let clock = NOW_MS;
    db.beforeWrite = ({ op, path }) => {
      if (op === "delete" && path.startsWith("ranking_entries/")) clock = NOW_MS + 2000;
    };

    const counts = await purgeUserData(db, FakeFieldValue, A, {
      deletedAtMs: NOW_MS, deadlineMs: NOW_MS + 1000, now: () => clock,
    });

    assert.equal(counts.partial, 1);
    assert.equal(counts.ranking_entries, 400);
    assert.equal(counts.window_snapshots_scrubbed, 0);
    assert.equal(db.log.filter((e) => e.op === "query" && e.path === "ranking_entries").length, 1);
    assert.equal(db.log.filter((e) => e.op === "query" && e.path === "leaderboard_snapshots").length, 0);
    assert.deepEqual(db.read("leaderboard_snapshots/in_window").top_highlights, [entry(A, 1)]);

    db.beforeWrite = null;
    const rest = await purgeUserData(db, FakeFieldValue, A, { deletedAtMs: NOW_MS, now: () => clock });
    assert.equal(rest.partial, 0);
    assert.equal(rest.ranking_entries, 1);
    assert.deepEqual(db.read("leaderboard_snapshots/in_window").top_highlights, []);
  });

  test("a deadline that is never reached changes nothing", async () => {
    const db = new FakeFirestore();
    seedEntries(db, 401);
    const counts = await purgeUserData(db, FakeFieldValue, A, {
      deletedAtMs: NOW_MS, deadlineMs: NOW_MS + 1000, now: () => NOW_MS,
    });
    assert.equal(counts.partial, 0);
    assert.equal(counts.ranking_entries, 401);
    assert.equal(counts.window_snapshots_scrubbed, 1);
  });
});

describe("tombstoned uids for snapshot builds", () => {
  test("loadTombstonedUids returns unexpired tombstones from one query", async () => {
    const db = new FakeFirestore();
    db.seed("deleted_users/live", { deleted_at: FakeTimestamp.fromMillis(NOW_MS - 1000), expire_at: FakeTimestamp.fromMillis(NOW_MS + 1000) });
    db.seed("deleted_users/old_live", { expire_at: FakeTimestamp.fromMillis(NOW_MS + 1) });
    db.seed("deleted_users/expired", { expire_at: FakeTimestamp.fromMillis(NOW_MS - 1) });
    db.seed("deleted_users/at_now", { expire_at: FakeTimestamp.fromMillis(NOW_MS) });

    const uids = await loadTombstonedUids(db, NOW_MS);

    assert.deepEqual([...uids].sort(), ["live", "old_live"]);
    const queries = db.log.filter((e) => e.path === "deleted_users");
    assert.deepEqual(queries.map((q) => [q.op, q.filters]), [["query", ["expire_at >"]]]);
  });

  test("loadTombstonedUids sees a tombstone written by writeTombstone", async () => {
    const db = new FakeFirestore({ clock: () => NOW_MS });
    await writeTombstone(db, FakeFieldValue, FakeTimestamp, A, NOW_MS);
    assert.deepEqual([...await loadTombstonedUids(db, NOW_MS + 29 * 24 * 60 * 60 * 1000)], [A]);
    assert.deepEqual([...await loadTombstonedUids(db, NOW_MS + 31 * 24 * 60 * 60 * 1000)], []);
  });

  test("excludeTombstonedEntries drops tombstoned uids and keeps order", () => {
    const entries = [
      { uid: "u1", score: 9 }, { uid: A, score: 8 }, { uid: "u2", score: 7 }, { uid: B, score: 6 }, { uid: "u3", score: 5 },
    ];
    assert.deepEqual(
      excludeTombstonedEntries(entries, new Set([A, B, "not_ranked"])).map((e) => e.uid),
      ["u1", "u2", "u3"],
    );
    assert.equal(excludeTombstonedEntries(entries, new Set()), entries);
    assert.equal(excludeTombstonedEntries(entries, undefined), entries);
    assert.deepEqual(excludeTombstonedEntries([], new Set([A])), []);
    assert.equal(entries.length, 5, "input not mutated");
  });
});

describe("quickPurge", () => {
  test("purges per-user data but never ranking_entries or snapshots", async () => {
    const db = new FakeFirestore();
    const { snap, snap2 } = seedWorld(db);
    db.seed("leaderboard_snapshots/recent", {
      generated_at: FakeTimestamp.fromMillis(Date.now()),
      top_highlights: [entry(A, 1)],
    });

    await quickPurge(db, FakeFieldValue, A);

    assert.equal(db.has(`test_sessions/s_${A}_1`), false);
    assert.equal(db.has(`users/${A}`), false);
    assert.equal(db.has(`leaderboard_dirty_users/${A}`), false);
    assert.deepEqual(db.read(`ai_generated_questions/q_${A}`), { prompt: "?" });

    assert.equal(db.has(`ranking_entries/${snap}_${A}`), true);
    assert.equal(db.has(`ranking_entries/${snap2}_${A}`), true);
    const touched = db.log.filter((e) =>
      e.path.startsWith("ranking_entries") || e.path.startsWith("leaderboard_snapshots"));
    assert.deepEqual(touched, [], "no read, query or write on ranking_entries or snapshots");
  });
});

describe("tombstones", () => {
  test("writeTombstone and isDeletedUser", async () => {
    const db = new FakeFirestore({ clock: () => NOW_MS });

    assert.equal(await isDeletedUser(db, A), false);
    const deletedAt = await writeTombstone(db, FakeFieldValue, FakeTimestamp, A, NOW_MS);
    assert.equal(deletedAt, NOW_MS);
    assert.equal(await isDeletedUser(db, A), true);
    assert.equal(await isDeletedUser(db, B), false);

    const tombstone = db.read(`deleted_users/${A}`);
    assert.equal(tombstone.deleted_at.toMillis(), NOW_MS);
    assert.equal(tombstone.expire_at.toMillis(), NOW_MS + 30 * 24 * 60 * 60 * 1000);
  });

  test("a retry keeps the original deleted_at", async () => {
    let clock = NOW_MS;
    const db = new FakeFirestore({ clock: () => clock });
    await writeTombstone(db, FakeFieldValue, FakeTimestamp, A, clock);
    db.seed(`deleted_users/${A}`, { ...db.read(`deleted_users/${A}`), last_swept_at: FakeTimestamp.fromMillis(clock) });

    clock = NOW_MS + 2 * 60 * 60 * 1000;
    const deletedAt = await writeTombstone(db, FakeFieldValue, FakeTimestamp, A, clock);

    assert.equal(deletedAt, NOW_MS);
    const tombstone = db.read(`deleted_users/${A}`);
    assert.equal(tombstone.deleted_at.toMillis(), NOW_MS);
    assert.equal(tombstone.last_swept_at.toMillis(), NOW_MS, "other fields survive");
  });

  test("a tombstone somehow missing deleted_at gets one", async () => {
    const db = new FakeFirestore({ clock: () => NOW_MS });
    db.seed(`deleted_users/${A}`, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 1) });
    const deletedAt = await writeTombstone(db, FakeFieldValue, FakeTimestamp, A, NOW_MS);
    assert.equal(deletedAt, NOW_MS);
    assert.equal(db.read(`deleted_users/${A}`).last_swept_at.toMillis(), NOW_MS - 1);
  });
});

describe("sweepRecentTombstones", () => {
  const HOUR = 60 * 60 * 1000;

  function makeSweepAuth(calls, errors = {}) {
    return {
      async deleteUser(uid) {
        calls.push(`deleteUser:${uid}`);
        if (errors[uid]) throw errors[uid];
      },
    };
  }

  function tombstone(db, uid, deletedAgoMs, extra = {}) {
    db.seed(`deleted_users/${uid}`, { deleted_at: FakeTimestamp.fromMillis(NOW_MS - deletedAgoMs), ...extra });
    db.seed(`test_sessions/late_${uid}`, { userId: uid });
  }

  function purgeOrder(db) {
    return db.log
      .filter((e) => e.op === "delete" && e.path.startsWith("leaderboard_dirty_users/"))
      .map((e) => e.path.split("/")[1]);
  }

  test("sweeps recent tombstones oldest first and skips expired windows", async () => {
    const db = new FakeFirestore();
    tombstone(db, "u_new", 1 * HOUR);
    tombstone(db, "u_old", 50 * HOUR);
    tombstone(db, "u_mid", 20 * HOUR);
    tombstone(db, "u_stale", 4 * 24 * HOUR);
    const calls = [];

    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth(calls), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });

    assert.deepEqual(result, { swept: 3, skipped: 0, failed: 0, partial: 0, stoppedEarly: false });
    assert.deepEqual(calls, ["deleteUser:u_old", "deleteUser:u_mid", "deleteUser:u_new"]);
    assert.deepEqual(purgeOrder(db), ["u_old", "u_mid", "u_new"]);
    assert.equal(db.has("test_sessions/late_u_new"), false);
    assert.equal(db.has("test_sessions/late_u_stale"), true);
    for (const uid of ["u_old", "u_mid", "u_new"]) {
      assert.equal(db.read(`deleted_users/${uid}`).last_swept_at.toMillis(), NOW_MS);
    }
    assert.equal(db.read("deleted_users/u_stale").last_swept_at, undefined);

    const query = db.log.find((e) => e.op === "query" && e.path === "deleted_users");
    assert.deepEqual(query.filters, ["deleted_at >="]);
    assert.deepEqual(query.orderBy, ["deleted_at asc"]);
  });

  test("skips tombstones swept within the last five hours", async () => {
    const db = new FakeFirestore();
    tombstone(db, "u_recent", 30 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 4 * HOUR) });
    tombstone(db, "u_due", 30 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 6 * HOUR) });
    const calls = [];

    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth(calls), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });

    assert.deepEqual(result, { swept: 1, skipped: 1, failed: 0, partial: 0, stoppedEarly: false });
    assert.deepEqual(calls, ["deleteUser:u_due"]);
    assert.equal(db.has("test_sessions/late_u_recent"), true);
    assert.equal(db.read("deleted_users/u_recent").last_swept_at.toMillis(), NOW_MS - 4 * HOUR);
  });

  test("stops starting tombstones once 450 seconds have elapsed", async () => {
    const db = new FakeFirestore();
    tombstone(db, "u1", 30 * HOUR);
    tombstone(db, "u2", 20 * HOUR);
    tombstone(db, "u3", 10 * HOUR);
    const calls = [];

    // Each deleteUser "takes" 200 s: u1 starts at 0 s, u2 at 200 s, u3 would start at 400 s,
    // and a fourth would start at 600 s. Only u1..u3 start; after u3 the budget is spent.
    let clock = NOW_MS;
    const auth = {
      async deleteUser(uid) {
        calls.push(`deleteUser:${uid}`);
        clock += 200 * 1000;
      },
    };
    tombstone(db, "u4", 5 * HOUR);

    const result = await sweepRecentTombstones({
      db, auth, FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => clock,
    });

    assert.deepEqual(calls, ["deleteUser:u1", "deleteUser:u2", "deleteUser:u3"]);
    assert.deepEqual(result, { swept: 3, skipped: 0, failed: 0, partial: 0, stoppedEarly: true });
    assert.equal(db.has("test_sessions/late_u4"), true);
    assert.equal(db.read("deleted_users/u4").last_swept_at, undefined);
  });

  test("an unswept tombstone goes before a backlog of re-sweeps, oldest sweep first", async () => {
    const db = new FakeFirestore();
    // Old deletions already swept, due again; by deleted_at they'd all come first.
    tombstone(db, "r_swept_late", 70 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 6 * HOUR) });
    tombstone(db, "r_swept_early", 60 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 20 * HOUR) });
    tombstone(db, "r_swept_mid", 50 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 12 * HOUR) });
    tombstone(db, "r_recent", 65 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 1 * HOUR) });
    tombstone(db, "n_new", 1 * HOUR);
    tombstone(db, "n_older", 2 * HOUR);

    // 200 s per tombstone: only three start inside the 450 s budget.
    let clock = NOW_MS;
    const calls = [];
    const auth = {
      async deleteUser(uid) {
        calls.push(`deleteUser:${uid}`);
        clock += 200 * 1000;
      },
    };

    const result = await sweepRecentTombstones({
      db, auth, FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => clock,
    });

    assert.deepEqual(calls, ["deleteUser:n_older", "deleteUser:n_new", "deleteUser:r_swept_early"]);
    assert.deepEqual(result, { swept: 3, skipped: 0, failed: 0, partial: 0, stoppedEarly: true });
    assert.equal(db.has("test_sessions/late_n_new"), false);
    assert.equal(db.has("test_sessions/late_r_swept_late"), true);
    assert.equal(db.read("deleted_users/r_recent").last_swept_at.toMillis(), NOW_MS - 1 * HOUR);
  });

  test("with budget to spare, orders unswept by deletion then swept by last sweep", async () => {
    const db = new FakeFirestore();
    tombstone(db, "r_b", 70 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 6 * HOUR) });
    tombstone(db, "r_a", 10 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 9 * HOUR) });
    tombstone(db, "r_skip", 40 * HOUR, { last_swept_at: FakeTimestamp.fromMillis(NOW_MS - 2 * HOUR) });
    tombstone(db, "n_b", 3 * HOUR);
    tombstone(db, "n_a", 30 * HOUR);
    const calls = [];

    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth(calls), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });

    assert.deepEqual(calls, ["deleteUser:n_a", "deleteUser:n_b", "deleteUser:r_a", "deleteUser:r_b"]);
    assert.deepEqual(result, { swept: 4, skipped: 1, failed: 0, partial: 0, stoppedEarly: false });
  });

  test("tolerates user-not-found and keeps going after a failure", async () => {
    const db = new FakeFirestore();
    tombstone(db, "u_gone", 30 * HOUR);
    tombstone(db, "u_broken", 20 * HOUR);
    tombstone(db, "u_live", 10 * HOUR);
    const calls = [];
    const auth = makeSweepAuth(calls, {
      u_gone: Object.assign(new Error("no user"), { code: "auth/user-not-found" }),
      u_broken: Object.assign(new Error("boom"), { code: "auth/internal-error" }),
    });

    const originalError = console.error;
    console.error = () => {};
    let result;
    try {
      result = await sweepRecentTombstones({
        db, auth, FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
      });
    } finally {
      console.error = originalError;
    }

    assert.deepEqual(result, { swept: 2, skipped: 0, failed: 1, partial: 0, stoppedEarly: false });
    assert.deepEqual(calls, ["deleteUser:u_gone", "deleteUser:u_broken", "deleteUser:u_live"]);
    assert.equal(db.has("test_sessions/late_u_gone"), false);
    assert.equal(db.has("test_sessions/late_u_live"), false);
    // The failed one is left unmarked so the next run retries it.
    assert.equal(db.read("deleted_users/u_broken").last_swept_at, undefined);
  });

  test("scrubs the race windows around deleted_at and the previous sweep, not around this sweep", async () => {
    const db = new FakeFirestore();
    const deletedAt = NOW_MS - 30 * HOUR;
    const previousSweep = NOW_MS - 10 * HOUR;
    db.seed(`deleted_users/${A}`, {
      deleted_at: FakeTimestamp.fromMillis(deletedAt),
      last_swept_at: FakeTimestamp.fromMillis(previousSweep),
    });
    const snapshot = (id, generatedAtMs) => db.seed(`leaderboard_snapshots/${id}`, {
      generated_at: FakeTimestamp.fromMillis(generatedAtMs),
      top_highlights: [entry(A, 1)],
    });
    snapshot("near_deletion", deletedAt + 60 * 1000);
    snapshot("near_previous_sweep", previousSweep - 60 * 1000);
    snapshot("near_sweep", NOW_MS);
    snapshot("between", deletedAt + 10 * HOUR);

    await sweepRecentTombstones({
      db, auth: makeSweepAuth([]), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });

    assert.deepEqual(db.read("leaderboard_snapshots/near_deletion").top_highlights, []);
    assert.deepEqual(db.read("leaderboard_snapshots/near_previous_sweep").top_highlights, []);
    assert.equal(db.read("leaderboard_snapshots/near_sweep").top_highlights.length, 1);
    assert.equal(db.read("leaderboard_snapshots/between").top_highlights.length, 1);
    assert.equal(db.read(`deleted_users/${A}`).last_swept_at.toMillis(), NOW_MS);
  });

  test("a tombstone younger than the race window is purged but not marked swept until a later sweep", async () => {
    const db = new FakeFirestore();
    const deletedAt = NOW_MS - 5 * 60 * 1000;
    db.seed(`deleted_users/${A}`, { deleted_at: FakeTimestamp.fromMillis(deletedAt) });
    db.seed(`test_sessions/late_${A}`, { userId: A });
    // A build that loaded tombstones just before the deletion, still running.
    const racing = "leaderboard_snapshots/racing";
    db.seed(racing, { status: "processing", generated_at: FakeTimestamp.fromMillis(deletedAt - 60 * 1000) });

    let clock = NOW_MS;
    const sweep = () => sweepRecentTombstones({
      db, auth: makeSweepAuth([]), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => clock,
    });

    const first = await sweep();
    assert.deepEqual(first, { swept: 0, skipped: 0, failed: 0, partial: 1, stoppedEarly: false });
    assert.equal(db.has(`test_sessions/late_${A}`), false, "the purge itself still ran");
    assert.equal(db.read(`deleted_users/${A}`).last_swept_at, undefined);
    assert.equal(db.read(`deleted_users/${A}`).last_attempt_at.toMillis(), NOW_MS);

    // The build finishes after the first sweep and lists A.
    db.seed(racing, {
      status: "ready",
      generated_at: FakeTimestamp.fromMillis(deletedAt + 8 * 60 * 1000),
      top_highlights: [entry(A, 1), entry(B, 2)],
    });

    // Within five hours of the attempt it is left alone.
    clock = NOW_MS + 2 * HOUR;
    assert.deepEqual(await sweep(), { swept: 0, skipped: 1, failed: 0, partial: 0, stoppedEarly: false });

    // The next scheduled sweep scrubs the deleted_at window and marks it swept.
    clock = NOW_MS + 6 * HOUR;
    assert.ok(clock >= deletedAt + RACE_WINDOW_AFTER_MS);
    assert.deepEqual(await sweep(), { swept: 1, skipped: 0, failed: 0, partial: 0, stoppedEarly: false });
    assert.deepEqual(db.read(racing).top_highlights, [entry(B, 2)]);
    assert.equal(db.read(`deleted_users/${A}`).last_swept_at.toMillis(), clock);
  });

  test("a tombstone exactly RACE_WINDOW_AFTER_MS old is marked swept", async () => {
    const db = new FakeFirestore();
    db.seed(`deleted_users/${A}`, { deleted_at: FakeTimestamp.fromMillis(NOW_MS - RACE_WINDOW_AFTER_MS) });
    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth([]), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });
    assert.deepEqual(result, { swept: 1, skipped: 0, failed: 0, partial: 0, stoppedEarly: false });
  });

  test("stamps last_attempt_at before touching the user, tolerating a tombstone gone by TTL", async () => {
    const db = new FakeFirestore();
    tombstone(db, "u_gone", 30 * HOUR);
    tombstone(db, "u_live", 20 * HOUR);
    const calls = [];
    db.beforeWrite = ({ op, path, data }) => {
      if (op === "update" && path.startsWith("deleted_users/")) {
        calls.push(`${Object.keys(data).join(",")}:${path.split("/")[1]}`);
        if (path === "deleted_users/u_gone") db._docs.delete(path);
      }
    };

    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth(calls), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });

    assert.deepEqual(result, { swept: 2, skipped: 0, failed: 0, partial: 0, stoppedEarly: false });
    assert.deepEqual(calls, [
      "last_attempt_at:u_gone", "deleteUser:u_gone", "last_swept_at:u_gone",
      "last_attempt_at:u_live", "deleteUser:u_live", "last_swept_at:u_live",
    ]);
    assert.equal(db.has("deleted_users/u_gone"), false, "not recreated by either stamp");
    assert.equal(db.has("test_sessions/late_u_gone"), false);
    assert.equal(db.read("deleted_users/u_live").last_attempt_at.toMillis(), NOW_MS);
  });

  test("orders never-attempted first, then by the latest attempt or sweep; skips recent attempts", async () => {
    const db = new FakeFirestore();
    const at = (hoursAgo) => FakeTimestamp.fromMillis(NOW_MS - hoursAgo * HOUR);
    // Its purge keeps dying: attempted 8 h ago, never swept.
    tombstone(db, "died_8h", 60 * HOUR, { last_attempt_at: at(8) });
    // Swept 20 h ago, then an attempt 7 h ago died.
    tombstone(db, "swept_then_died_7h", 70 * HOUR, { last_swept_at: at(20), last_attempt_at: at(7) });
    // Swept 6 h ago; its attempt stamp (earlier) is older than the sweep.
    tombstone(db, "swept_6h", 65 * HOUR, { last_attempt_at: at(6.1), last_swept_at: at(6) });
    tombstone(db, "never", 1 * HOUR);
    // An attempt 2 h ago with no sweep since: in flight or died recently.
    tombstone(db, "attempting", 50 * HOUR, { last_attempt_at: at(2) });
    tombstone(db, "attempting_after_old_sweep", 55 * HOUR, { last_swept_at: at(20), last_attempt_at: at(2) });
    // Attempt 2 h ago that did finish: skipped by the last_swept_at rule.
    tombstone(db, "swept_recently", 45 * HOUR, { last_attempt_at: at(2.1), last_swept_at: at(2) });
    const calls = [];

    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth(calls), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => NOW_MS,
    });

    assert.deepEqual(calls, [
      "deleteUser:never", "deleteUser:died_8h", "deleteUser:swept_then_died_7h", "deleteUser:swept_6h",
    ]);
    assert.deepEqual(result, { swept: 4, skipped: 3, failed: 0, partial: 0, stoppedEarly: false });
    assert.equal(db.read("deleted_users/attempting").last_attempt_at.toMillis(), NOW_MS - 2 * HOUR);
  });

  test("a purge that hits its deadline ends the sweep without marking the tombstone swept", async () => {
    const db = new FakeFirestore();
    tombstone(db, "u_big", 30 * HOUR);
    tombstone(db, "u_next", 20 * HOUR);
    for (let i = 0; i < 401; i++) {
      db.seed(`ranking_entries/s${String(i).padStart(3, "0")}_u_big`, { snapshot_id: `s${i}`, uid: "u_big" });
    }

    // The first page of ranking entries takes the sweep past its 500 s purge deadline.
    let clock = NOW_MS;
    db.beforeWrite = ({ op, path }) => {
      if (op === "delete" && path.startsWith("ranking_entries/")) clock = NOW_MS + 501 * 1000;
    };
    const calls = [];
    const result = await sweepRecentTombstones({
      db, auth: makeSweepAuth(calls), FieldValue: FakeFieldValue, Timestamp: FakeTimestamp, now: () => clock,
    });

    assert.deepEqual(result, { swept: 0, skipped: 0, failed: 0, partial: 1, stoppedEarly: true });
    assert.deepEqual(calls, ["deleteUser:u_big"]);
    assert.equal(db.paths().filter((p) => p.startsWith("ranking_entries/")).length, 1);
    assert.equal(db.read("deleted_users/u_big").last_swept_at, undefined);
    assert.equal(db.read("deleted_users/u_big").last_attempt_at.toMillis(), NOW_MS);
    assert.equal(db.has("test_sessions/late_u_next"), true);
  });
});

describe("deleteAccount handler", () => {
  function makeAuth(calls, { deleteError } = {}) {
    return {
      async revokeRefreshTokens(uid) {
        calls.push(`revokeRefreshTokens:${uid}`);
      },
      async deleteUser(uid) {
        calls.push(`deleteUser:${uid}`);
        if (deleteError) throw deleteError;
      },
    };
  }

  function request(uid, provider, authTime, identities) {
    const firebase = { sign_in_provider: provider };
    if (identities !== undefined) firebase.identities = identities;
    return {
      auth: { uid, token: { auth_time: authTime, firebase } },
      data: {},
    };
  }

  function setup(authOptions, { clock = () => NOW_MS } = {}) {
    const db = new FakeFirestore({ clock });
    seedWorld(db);
    const calls = [];

    // Mirror Firestore activity into the same timeline as the Auth calls.
    const push = db.log.push.bind(db.log);
    db.log.push = (e) => {
      if (e.path === `deleted_users/${A}` && ["set", "create"].includes(e.op)) calls.push("tombstone");
      if (e.path === `leaderboard_dirty_users/${A}` && e.op === "delete") calls.push("purge:start");
      if (e.path === `users/${A}` && e.op === "recursiveDelete") calls.push("purge:users");
      return push(e);
    };

    const handler = makeDeleteAccountHandler({
      db,
      auth: makeAuth(calls, authOptions),
      FieldValue: FakeFieldValue,
      Timestamp: FakeTimestamp,
      now: () => NOW_MS,
    });
    return { db, calls, handler };
  }

  async function expectRecentLogin(handler, req) {
    await assert.rejects(handler(req), { code: "failed-precondition", message: "requires-recent-login" });
  }

  test("rejects unauthenticated callers", async () => {
    const { handler, calls, db } = setup();
    await assert.rejects(handler({ data: {} }), { code: "unauthenticated" });
    assert.deepEqual(calls, []);
    assert.equal(db.has(`deleted_users/${A}`), false);
  });

  test("requires a recent login for apple.com", async () => {
    const { handler, calls, db } = setup();
    await expectRecentLogin(handler, request(A, "apple.com", NOW_S - 301));
    assert.deepEqual(calls, []);
    assert.equal(db.has(`test_sessions/s_${A}_1`), true);
    assert.equal(db.has(`deleted_users/${A}`), false);
  });

  test("accepts a login exactly 300 seconds old", async () => {
    const { handler } = setup();
    assert.deepEqual(await handler(request(A, "google.com", NOW_S - 300)), { deleted: true });
  });

  test("requires a recent login when auth_time is missing or not a number", async () => {
    const { handler } = setup();
    await expectRecentLogin(handler, request(A, "google.com", undefined));
    await expectRecentLogin(handler, request(A, "google.com", String(NOW_S)));
  });

  test("exempts a true guest (anonymous, no identities) with an old auth_time", async () => {
    for (const identities of [undefined, {}]) {
      const { handler, db } = setup();
      const result = await handler(request(A, "anonymous", NOW_S - 90 * 24 * 60 * 60, identities));
      assert.deepEqual(result, { deleted: true });
      assert.equal(db.has(`test_sessions/s_${A}_1`), false);
    }
  });

  test("a linked guest (anonymous provider, non-empty identities) needs a recent login", async () => {
    const { handler, calls, db } = setup();
    const linked = { "apple.com": ["001234.abcd"], email: ["a@example.com"] };

    await expectRecentLogin(handler, request(A, "anonymous", NOW_S - 90 * 24 * 60 * 60, linked));
    await expectRecentLogin(handler, request(A, "anonymous", undefined, linked));
    assert.deepEqual(calls, []);
    assert.equal(db.has(`deleted_users/${A}`), false);

    assert.deepEqual(await handler(request(A, "anonymous", NOW_S - 10, linked)), { deleted: true });
  });

  test("runs tombstone, deleteUser, quick purge in order and leaves ranking data alone", async () => {
    const { handler, calls, db } = setup();
    const result = await handler(request(A, "apple.com", NOW_S - 30));

    assert.deepEqual(result, { deleted: true });
    assert.deepEqual(calls, [
      "tombstone",
      `deleteUser:${A}`,
      "purge:start",
      "purge:users",
    ]);
    assert.ok(!calls.some((c) => c.startsWith("revokeRefreshTokens")), "no separate revoke call");
    assert.equal(await isDeletedUser(db, A), true);
    assert.equal(db.has(`users/${A}`), false);
    assert.equal(db.has(`users/${B}`), true);

    assert.equal(db.has("ranking_entries/iq_global_all_weekly_2026-09-16_user_a"), true);
    const touched = db.log.filter((e) =>
      e.path.startsWith("ranking_entries") || e.path.startsWith("leaderboard_snapshots"));
    assert.deepEqual(touched, [], "the callable does not touch ranking_entries or snapshots");
  });

  test("a retry succeeds and keeps the original deleted_at", async () => {
    let clock = NOW_MS;
    const { handler, db } = setup(undefined, { clock: () => clock });
    await handler(request(A, "google.com", NOW_S));

    clock = NOW_MS + 60 * 1000;
    const notFound = Object.assign(new Error("no user"), { code: "auth/user-not-found" });
    const retry = makeDeleteAccountHandler({
      db,
      auth: makeAuth([], { deleteError: notFound }),
      FieldValue: FakeFieldValue,
      Timestamp: FakeTimestamp,
      now: () => NOW_MS,
    });
    assert.deepEqual(await retry(request(A, "google.com", NOW_S)), { deleted: true });
    assert.equal(db.read(`deleted_users/${A}`).deleted_at.toMillis(), NOW_MS);
  });

  test("tolerates auth/user-not-found from Auth", async () => {
    const notFound = Object.assign(new Error("no user"), { code: "auth/user-not-found" });
    const { handler, db } = setup({ deleteError: notFound });

    const result = await handler(request(A, "google.com", NOW_S));

    assert.deepEqual(result, { deleted: true });
    assert.equal(db.has(`users/${A}`), false);
  });

  test("maps unexpected failures to internal, with the tombstone left for the sweep", async () => {
    const boom = Object.assign(new Error("backend exploded"), { code: "auth/internal-error" });
    const { handler, db } = setup({ deleteError: boom });
    const originalError = console.error;
    console.error = () => {};
    try {
      await assert.rejects(handler(request(A, "google.com", NOW_S)), (error) => {
        assert.equal(error.code, "internal");
        assert.doesNotMatch(error.message, /exploded/);
        return true;
      });
    } finally {
      console.error = originalError;
    }
    assert.equal(await isDeletedUser(db, A), true);
  });
});
