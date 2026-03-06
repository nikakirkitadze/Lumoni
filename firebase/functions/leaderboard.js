const crypto = require("crypto");

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  FieldPath,
  FieldValue,
  Timestamp,
  getFirestore,
} = require("firebase-admin/firestore");

const db = getFirestore();

const COLLECTIONS = {
  testSessions: "test_sessions",
  iqQuestions: "iq_questions",
  eqQuestions: "eq_questions",
  users: "users",
  countries: "countries",
  leaderboardProfiles: "leaderboard_profiles",
  leaderboardSnapshots: "leaderboard_snapshots",
  rankingEntries: "ranking_entries",
  userBestScores: "user_best_scores",
  suspiciousSessions: "suspicious_sessions",
  rankingFeatures: "ranking_features",
  leaderboardDirtyUsers: "leaderboard_dirty_users",
};

const METRICS = ["iq", "eq"];
const PERIODS = ["weekly", "monthly", "all_time"];
const PAGE_SIZE = 50;
const MAX_SNAPSHOT_ENTRIES = 50000;
const RANKING_VERSION = 1;
const EPSILON = 1e-9;

const PERIOD_CONFIG = {
  weekly: {
    days: 7,
    minSessions: 3,
    minActiveDays: 2,
    topK: 5,
    decayDays: 5,
  },
  monthly: {
    days: 30,
    minSessions: 5,
    minActiveDays: 2,
    topK: 12,
    decayDays: 9,
  },
  all_time: {
    days: null,
    minSessions: 10,
    minActiveDays: 2,
    topK: 40,
    decayDays: 30,
  },
};

const SUSPICIOUS_SPEED_MIN_SECONDS = {
  iq: 4,
  eq: 2,
};

const MODERATION_BLOCKLIST = [
  "admin",
  "moderator",
  "support",
  "lumoni",
  "official",
  "fuck",
  "shit",
  "bitch",
  "asshole",
];

exports.submitAssessmentResult = onCall(
  { region: "us-central1", maxInstances: 100 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const uid = request.auth.uid;
    const data = request.data || {};

    const testType = typeof data.testType === "string" ? data.testType : "iq";
    if (!METRICS.includes(testType)) {
      throw new HttpsError("invalid-argument", "Invalid testType.");
    }

    const questionIds = Array.isArray(data.questionIds) ? data.questionIds : [];
    const answers = data.answers && typeof data.answers === "object" ? data.answers : {};
    const sessionId = typeof data.sessionId === "string" && data.sessionId
      ? data.sessionId
      : db.collection(COLLECTIONS.testSessions).doc().id;

    if (questionIds.length === 0) {
      throw new HttpsError("invalid-argument", "questionIds are required.");
    }

    const startedAt = _parseTime(data.startedAt) || new Date();
    const completedAt = _parseTime(data.completedAt) || new Date();
    const durationSeconds = Math.max(
      0,
      Math.round((completedAt.getTime() - startedAt.getTime()) / 1000),
    );

    const answerHash = _computeAnswerHash(testType, questionIds, answers);

    const questionMap = await _loadQuestionsByIds(testType, questionIds);
    const scoreResult = _computeOfficialScore({
      testType,
      questionIds,
      answers,
      questionMap,
      durationSeconds,
    });

    const suspicion = await _evaluateSuspicion({
      uid,
      testType,
      questionIds,
      answers,
      durationSeconds,
      answerHash,
      officialScore: scoreResult.score,
      deviceHash: typeof data.deviceHash === "string" ? data.deviceHash : null,
    });

    const validationStatus = suspicion.isSuspicious ? "pending_review" : "validated";

    const sessionPayload = {
      userId: uid,
      testType,
      questionIds,
      answers,
      startedAt: Timestamp.fromDate(startedAt),
      completedAt: Timestamp.fromDate(completedAt),
      timeSpentSeconds: durationSeconds,
      score: scoreResult.score,
      categoryScores: scoreResult.categoryScores,
      validation_status: validationStatus,
      validated_for_leaderboard: !suspicion.isSuspicious,
      risk_score: suspicion.riskScore,
      risk_reasons: suspicion.reasons,
      answer_hash: answerHash,
      difficulty_avg: scoreResult.difficultyAverage,
      difficulty_weighted_score: scoreResult.normalizedPerformance,
      score_percentile_estimate: scoreResult.percentileEstimate,
      score_meta: {
        raw_accuracy: scoreResult.rawAccuracy,
        normalized_performance: scoreResult.normalizedPerformance,
        difficulty_factor: scoreResult.difficultyFactor,
      },
      server_scored_at: Timestamp.now(),
      updatedAt: Timestamp.now(),
      createdAt: FieldValue.serverTimestamp(),
    };

    await db
      .collection(COLLECTIONS.testSessions)
      .doc(sessionId)
      .set(sessionPayload, { merge: true });

    if (suspicion.isSuspicious) {
      await db
        .collection(COLLECTIONS.suspiciousSessions)
        .doc(sessionId)
        .set({
          uid,
          session_id: sessionId,
          test_type: testType,
          risk_score: suspicion.riskScore,
          reasons: suspicion.reasons,
          answer_hash: answerHash,
          status: "pending_review",
          device_hash: typeof data.deviceHash === "string" ? data.deviceHash : null,
          ip_hash: _hashIp(request.rawRequest?.ip || ""),
          created_at: Timestamp.now(),
          updated_at: Timestamp.now(),
        }, { merge: true });
    }

    if (!suspicion.isSuspicious) {
      await _markUserDirty(uid, sessionId);
    }

    return {
      sessionId,
      validationStatus,
      score: scoreResult.score,
      percentileEstimate: scoreResult.percentileEstimate,
      riskScore: suspicion.riskScore,
      riskReasons: suspicion.reasons,
    };
  },
);

exports.onValidatedSessionCreated = onDocumentWritten(
  {
    region: "us-central1",
    document: `${COLLECTIONS.testSessions}/{sessionId}`,
    maxInstances: 50,
  },
  async (event) => {
    const before = event.data.before.exists ? event.data.before.data() : null;
    const after = event.data.after.exists ? event.data.after.data() : null;

    if (!after) {
      return;
    }

    const nowValidated =
      after.validation_status === "validated" &&
      after.validated_for_leaderboard === true;

    const wasValidated =
      before &&
      before.validation_status === "validated" &&
      before.validated_for_leaderboard === true;

    if (!nowValidated && !wasValidated) {
      return;
    }

    const uid = after.userId;
    if (!uid) {
      return;
    }

    await _markUserDirty(uid, event.params.sessionId);
  },
);

exports.onLeaderboardProfileWrite = onDocumentWritten(
  {
    region: "us-central1",
    document: `${COLLECTIONS.leaderboardProfiles}/{uid}`,
    maxInstances: 30,
  },
  async (event) => {
    if (!event.data.after.exists) {
      return;
    }

    const uid = event.params.uid;
    const profile = event.data.after.data() || {};
    const updates = {};

    const sanitizedDisplayName = _sanitizeDisplayName(profile.display_name);
    if (sanitizedDisplayName !== (profile.display_name || "")) {
      updates.display_name = sanitizedDisplayName;
    }

    if (profile.public_alias) {
      const sanitizedAlias = _sanitizeDisplayName(profile.public_alias);
      if (sanitizedAlias !== profile.public_alias) {
        updates.public_alias = sanitizedAlias;
      }
    }

    if (typeof profile.country_code === "string") {
      const normalizedCountry = profile.country_code.toUpperCase().trim();
      if (normalizedCountry !== profile.country_code) {
        updates.country_code = normalizedCountry;
      }
    }

    if (Object.keys(updates).length === 0) {
      return;
    }

    updates.updated_at = Timestamp.now();

    await db
      .collection(COLLECTIONS.leaderboardProfiles)
      .doc(uid)
      .set(updates, { merge: true });
  },
);

exports.aggregateIncremental = onSchedule(
  {
    region: "us-central1",
    schedule: "every 5 minutes",
    maxInstances: 1,
    timeoutSeconds: 540,
  },
  async () => {
    const dirtySnap = await db
      .collection(COLLECTIONS.leaderboardDirtyUsers)
      .orderBy("updated_at", "asc")
      .limit(500)
      .get();

    if (dirtySnap.empty) {
      return;
    }

    for (const doc of dirtySnap.docs) {
      const data = doc.data();
      const uid = data.uid || doc.id;
      await _recomputeUserFeatures(uid);
      await doc.ref.delete();
    }
  },
);

exports.buildWeeklySnapshot = onSchedule(
  {
    region: "us-central1",
    schedule: "every 60 minutes",
    maxInstances: 1,
    timeoutSeconds: 540,
  },
  async () => {
    await _buildSnapshotsForPeriod("weekly");
  },
);

exports.buildMonthlySnapshot = onSchedule(
  {
    region: "us-central1",
    schedule: "every 120 minutes",
    maxInstances: 1,
    timeoutSeconds: 540,
  },
  async () => {
    await _buildSnapshotsForPeriod("monthly");
  },
);

exports.buildAllTimeSnapshot = onSchedule(
  {
    region: "us-central1",
    schedule: "every day 00:10",
    maxInstances: 1,
    timeoutSeconds: 540,
  },
  async () => {
    await _buildSnapshotsForPeriod("all_time");
  },
);

exports.cleanupSnapshots = onSchedule(
  {
    region: "us-central1",
    schedule: "every day 02:00",
    maxInstances: 1,
    timeoutSeconds: 540,
  },
  async () => {
    await _cleanupOldSnapshots();
  },
);

exports.recomputeUserRank = onCall(
  { region: "us-central1", maxInstances: 100 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }

    const uid = request.auth.uid;
    const filter = request.data || {};

    const metric = METRICS.includes(filter.metric) ? filter.metric : "iq";
    const period = PERIODS.includes(filter.period) ? filter.period : "weekly";
    const scopeType = ["global", "country", "friends"].includes(filter.scope_type)
      ? filter.scope_type
      : "global";
    const scopeValue = typeof filter.scope_value === "string" && filter.scope_value
      ? filter.scope_value
      : "all";

    await _recomputeUserFeatures(uid);
    await _buildSnapshotForScope({ metric, period, scopeType, scopeValue });

    const snapshot = await _getLatestReadySnapshot({
      metric,
      period,
      scopeType,
      scopeValue,
    });

    if (!snapshot) {
      return { status: "queued" };
    }

    const entryDoc = await db
      .collection(COLLECTIONS.rankingEntries)
      .doc(`${snapshot.id}_${uid}`)
      .get();

    if (!entryDoc.exists) {
      return {
        status: "ready",
        snapshotId: snapshot.id,
        ranked: false,
      };
    }

    const entry = entryDoc.data() || {};
    return {
      status: "ready",
      snapshotId: snapshot.id,
      ranked: true,
      rank: entry.rank || null,
      score: entry.score || null,
      percentile: entry.percentile || null,
      tier: entry.tier || null,
    };
  },
);

async function _markUserDirty(uid, sessionId) {
  await db
    .collection(COLLECTIONS.leaderboardDirtyUsers)
    .doc(uid)
    .set({
      uid,
      last_session_id: sessionId,
      updated_at: Timestamp.now(),
    }, { merge: true });
}

async function _recomputeUserFeatures(uid) {
  const profileDoc = await db
    .collection(COLLECTIONS.leaderboardProfiles)
    .doc(uid)
    .get();
  const userDoc = await db.collection(COLLECTIONS.users).doc(uid).get();

  const profile = profileDoc.exists ? profileDoc.data() : {};
  const user = userDoc.exists ? userDoc.data() : {};

  const displayName = _deriveDisplayName(profile, user, uid);
  const visibility = _deriveVisibility(profile);
  const countryCode = _resolveCountryCode(profile, user);

  const sessionSnap = await db
    .collection(COLLECTIONS.testSessions)
    .where("userId", "==", uid)
    .where("validation_status", "==", "validated")
    .where("validated_for_leaderboard", "==", true)
    .orderBy("completedAt", "desc")
    .limit(500)
    .get();

  const sessions = sessionSnap.docs.map((doc) => {
    const data = doc.data() || {};
    return {
      id: doc.id,
      testType: data.testType,
      completedAt: _toDate(data.completedAt),
      score: typeof data.score === "number" ? data.score : 0,
      normalizedPerformance: _asNumber(data.difficulty_weighted_score),
      difficultyAvg: _asNumber(data.difficulty_avg),
      validated: data.validation_status === "validated" &&
        data.validated_for_leaderboard === true,
    };
  });

  const userBestScoreUpdate = {
    uid,
    display_name: displayName,
    visibility: visibility.visibilityScope,
    hide_profile: visibility.hideProfile,
    anonymous_mode: visibility.anonymousMode,
    country_code: countryCode,
    updated_at: Timestamp.now(),
  };

  for (const metric of METRICS) {
    const metricSessions = sessions.filter((session) => session.testType === metric);

    for (const period of PERIODS) {
      const feature = _computeFeatureForPeriod(metricSessions, period, metric);

      userBestScoreUpdate[`${metric}_${period}`] = {
        eligible: feature.eligible,
        rank_score: feature.rankScore,
        best_validated_score: feature.bestValidatedScore,
        consistency: feature.consistency,
        recency: feature.recency,
        difficulty: feature.difficulty,
        participation: feature.participation,
        validated_count: feature.validatedCount,
        distinct_days: feature.distinctDays,
        last_validated_at: feature.lastValidatedAt
          ? Timestamp.fromDate(feature.lastValidatedAt)
          : null,
        updated_at: Timestamp.now(),
      };

      await _upsertRankingFeature({
        uid,
        displayName,
        metric,
        period,
        scopeType: "global",
        scopeValue: "all",
        countryCode,
        visibility,
        feature,
      });

      await _upsertRankingFeature({
        uid,
        displayName,
        metric,
        period,
        scopeType: "country",
        scopeValue: countryCode,
        countryCode,
        visibility,
        feature,
      });
    }
  }

  await db
    .collection(COLLECTIONS.userBestScores)
    .doc(uid)
    .set(userBestScoreUpdate, { merge: true });
}

function _computeFeatureForPeriod(sessions, period, metric) {
  const config = PERIOD_CONFIG[period];
  const now = new Date();
  const windowStart = config.days === null
    ? new Date(0)
    : new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  const filtered = sessions
    .filter((session) => session.completedAt && session.completedAt >= windowStart)
    .sort((a, b) => b.completedAt.getTime() - a.completedAt.getTime());

  const validatedCount = filtered.length;
  const distinctDays = new Set(
    filtered.map((session) => _dateKey(session.completedAt)),
  ).size;

  if (validatedCount === 0) {
    return {
      eligible: false,
      rankScore: 0,
      bestValidatedScore: 0,
      consistency: 0,
      recency: 0,
      difficulty: 0,
      participation: 0,
      validatedCount,
      distinctDays,
      lastValidatedAt: null,
    };
  }

  const topSessions = filtered
    .slice()
    .sort((a, b) => _normalizedValue(b, metric) - _normalizedValue(a, metric))
    .slice(0, config.topK);

  const normalizedValues = topSessions.map((session) => _normalizedValue(session, metric));
  const best = normalizedValues.length ? Math.max(...normalizedValues) : 0;
  const consistency = normalizedValues.length
    ? Math.max(0, 1 - (_stdDev(normalizedValues) * 2.2))
    : 0;

  const lastValidatedAt = filtered[0].completedAt;
  const daysSinceLast = Math.max(
    0,
    (now.getTime() - lastValidatedAt.getTime()) / (24 * 60 * 60 * 1000),
  );
  const recency = Math.exp(-daysSinceLast / config.decayDays);

  const difficulty = _clamp(
    (topSessions.reduce((acc, session) => acc + (session.difficultyAvg || 1), 0) /
      Math.max(1, topSessions.length)) / 5,
    0,
    1,
  );

  const participation = _clamp(
    Math.log(1 + validatedCount) / Math.log(1 + config.minSessions * 3),
    0,
    1,
  );

  const baselineMean = metric === "iq" ? 0.55 : 0.6;
  const shrinkK = 8;
  const bestAdjusted =
    (validatedCount / (validatedCount + shrinkK)) * best +
    (shrinkK / (validatedCount + shrinkK)) * baselineMean;

  const rankScore = 1000 * (
    0.55 * bestAdjusted +
    0.2 * consistency +
    0.1 * recency +
    0.1 * difficulty +
    0.05 * participation
  );

  const eligible =
    validatedCount >= config.minSessions &&
    distinctDays >= config.minActiveDays;

  return {
    eligible,
    rankScore: _round(rankScore, 3),
    bestValidatedScore: _round(bestAdjusted, 5),
    consistency: _round(consistency, 5),
    recency: _round(recency, 5),
    difficulty: _round(difficulty, 5),
    participation: _round(participation, 5),
    validatedCount,
    distinctDays,
    lastValidatedAt,
  };
}

async function _upsertRankingFeature({
  uid,
  displayName,
  metric,
  period,
  scopeType,
  scopeValue,
  countryCode,
  visibility,
  feature,
}) {
  const docId = `${metric}_${period}_${scopeType}_${scopeValue}_${uid}`;
  const isVisible = _isVisibleInScope({ visibility, scopeType, countryCode, scopeValue });

  await db
    .collection(COLLECTIONS.rankingFeatures)
    .doc(docId)
    .set({
      uid,
      metric,
      period,
      scope_type: scopeType,
      scope_value: scopeValue,
      display_name: displayName,
      country_code: countryCode,
      is_visible: isVisible,
      eligible: feature.eligible,
      rank_score: feature.rankScore,
      best_validated_score: feature.bestValidatedScore,
      consistency: feature.consistency,
      recency: feature.recency,
      difficulty: feature.difficulty,
      participation: feature.participation,
      validated_count: feature.validatedCount,
      distinct_days: feature.distinctDays,
      last_validated_at: feature.lastValidatedAt
        ? Timestamp.fromDate(feature.lastValidatedAt)
        : null,
      updated_at: Timestamp.now(),
      version: RANKING_VERSION,
    }, { merge: true });
}

async function _buildSnapshotsForPeriod(period) {
  for (const metric of METRICS) {
    await _buildSnapshotForScope({
      metric,
      period,
      scopeType: "global",
      scopeValue: "all",
    });

    const countries = await db
      .collection(COLLECTIONS.countries)
      .where("enabled", "==", true)
      .get();

    for (const countryDoc of countries.docs) {
      await _buildSnapshotForScope({
        metric,
        period,
        scopeType: "country",
        scopeValue: countryDoc.id,
      });
    }
  }
}

async function _buildSnapshotForScope({ metric, period, scopeType, scopeValue }) {
  const now = new Date();
  const config = PERIOD_CONFIG[period];
  const windowStart = config.days === null
    ? new Date(0)
    : new Date(now.getTime() - config.days * 24 * 60 * 60 * 1000);

  const snapshotId = _snapshotId({ metric, scopeType, scopeValue, period, now });
  const snapshotRef = db.collection(COLLECTIONS.leaderboardSnapshots).doc(snapshotId);

  await snapshotRef.set({
    metric,
    scope_type: scopeType,
    scope_value: scopeValue,
    period,
    status: "processing",
    version: RANKING_VERSION,
    window_start: Timestamp.fromDate(windowStart),
    window_end: Timestamp.fromDate(now),
    generated_at: Timestamp.now(),
    updated_at: Timestamp.now(),
  }, { merge: true });

  const entries = await _collectFeatureEntries({
    metric,
    period,
    scopeType,
    scopeValue,
  });

  if (!entries.length) {
    await snapshotRef.set({
      status: "ready",
      total_eligible: 0,
      top_highlights: [],
      generated_at: Timestamp.now(),
      updated_at: Timestamp.now(),
    }, { merge: true });
    return null;
  }

  const rankedEntries = _rankEntries(entries);
  const totalEligible = rankedEntries.length;

  let batch = db.batch();
  let opCount = 0;

  for (let i = 0; i < rankedEntries.length; i++) {
    const entry = rankedEntries[i];
    const docRef = db
      .collection(COLLECTIONS.rankingEntries)
      .doc(`${snapshotId}_${entry.uid}`);

    batch.set(docRef, {
      snapshot_id: snapshotId,
      uid: entry.uid,
      display_name: entry.displayName,
      rank: entry.rank,
      score: entry.score,
      percentile: entry.percentile,
      tier: entry.tier,
      country_code: entry.countryCode || null,
      metric,
      period,
      scope_type: scopeType,
      scope_value: scopeValue,
      is_visible: true,
      validated_count: entry.validatedCount,
      best_score: entry.bestScore,
      consistency: entry.consistency,
      recency: entry.recency,
      difficulty: entry.difficulty,
      participation: entry.participation,
      updated_at: Timestamp.now(),
      version: RANKING_VERSION,
    }, { merge: true });

    opCount++;
    if (opCount >= 450) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  await _writeSnapshotPages(snapshotRef, rankedEntries);

  const highlights = rankedEntries
    .slice(0, 3)
    .map((entry) => ({
      uid: entry.uid,
      display_name: entry.displayName,
      rank: entry.rank,
      score: entry.score,
      badge: entry.tier,
    }));

  await snapshotRef.set({
    status: "ready",
    generated_at: Timestamp.now(),
    updated_at: Timestamp.now(),
    total_eligible: totalEligible,
    top_highlights: highlights,
    percentile_histogram: _percentileHistogram(rankedEntries),
  }, { merge: true });

  if (scopeType === "country") {
    await db.collection(COLLECTIONS.countries).doc(scopeValue).set({
      last_snapshot_id: snapshotId,
      last_generated_at: Timestamp.now(),
    }, { merge: true });
  }

  return snapshotId;
}

async function _collectFeatureEntries({ metric, period, scopeType, scopeValue }) {
  const entries = [];
  let cursor = null;

  while (entries.length < MAX_SNAPSHOT_ENTRIES) {
    let query = db
      .collection(COLLECTIONS.rankingFeatures)
      .where("metric", "==", metric)
      .where("period", "==", period)
      .where("scope_type", "==", scopeType)
      .where("scope_value", "==", scopeValue)
      .where("eligible", "==", true)
      .where("is_visible", "==", true)
      .orderBy("rank_score", "desc")
      .limit(PAGE_SIZE);

    if (cursor) {
      query = query.startAfter(cursor);
    }

    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      entries.push({
        uid: data.uid,
        displayName: data.display_name || "Lumoni User",
        score: _asNumber(data.rank_score),
        countryCode: data.country_code || null,
        validatedCount: data.validated_count || 0,
        bestScore: _asNumber(data.best_validated_score),
        consistency: _asNumber(data.consistency),
        recency: _asNumber(data.recency),
        difficulty: _asNumber(data.difficulty),
        participation: _asNumber(data.participation),
      });
    }

    cursor = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < PAGE_SIZE) {
      break;
    }
  }

  entries.sort((a, b) => b.score - a.score);
  return entries.slice(0, MAX_SNAPSHOT_ENTRIES);
}

function _rankEntries(entries) {
  const n = entries.length;
  const ranked = [];

  let i = 0;
  while (i < n) {
    const start = i;
    const score = entries[i].score;

    while (i + 1 < n && Math.abs(entries[i + 1].score - score) <= EPSILON) {
      i++;
    }

    const end = i;
    const startRank = start + 1;
    const endRank = end + 1;
    const tieAvgRank = (startRank + endRank) / 2;
    const percentile = _clamp(100 * ((n - tieAvgRank + 0.5) / n), 0.1, 99.9);
    const tier = _tierFromPercentile(percentile);

    for (let idx = start; idx <= end; idx++) {
      ranked.push({
        uid: entries[idx].uid,
        displayName: entries[idx].displayName,
        rank: startRank,
        score: _round(entries[idx].score, 3),
        percentile: _round(percentile, 1),
        tier,
        countryCode: entries[idx].countryCode,
        validatedCount: entries[idx].validatedCount,
        bestScore: entries[idx].bestScore,
        consistency: entries[idx].consistency,
        recency: entries[idx].recency,
        difficulty: entries[idx].difficulty,
        participation: entries[idx].participation,
      });
    }

    i++;
  }

  return ranked;
}

async function _writeSnapshotPages(snapshotRef, entries) {
  const pagesCol = snapshotRef.collection("pages");

  let batch = db.batch();
  let opCount = 0;

  for (let page = 0; page * PAGE_SIZE < entries.length; page++) {
    const start = page * PAGE_SIZE;
    const end = Math.min(entries.length, start + PAGE_SIZE);
    const pageEntries = entries.slice(start, end).map((entry) => ({
      uid: entry.uid,
      display_name: entry.displayName,
      rank: entry.rank,
      score: entry.score,
      percentile: entry.percentile,
      tier: entry.tier,
      country_code: entry.countryCode,
      validated_count: entry.validatedCount,
      best_score: entry.bestScore,
      consistency: entry.consistency,
      recency: entry.recency,
      difficulty: entry.difficulty,
      participation: entry.participation,
      is_visible: true,
    }));

    const pageRef = pagesCol.doc(`${page}`);
    batch.set(pageRef, {
      page,
      rank_start: pageEntries.length ? pageEntries[0].rank : null,
      rank_end: pageEntries.length ? pageEntries[pageEntries.length - 1].rank : null,
      entries: pageEntries,
      updated_at: Timestamp.now(),
    }, { merge: true });

    opCount++;
    if (opCount >= 450) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }
}

function _percentileHistogram(entries) {
  const buckets = {
    "top_1": 0,
    "top_5": 0,
    "top_10": 0,
    "top_25": 0,
    "top_50": 0,
    "rest": 0,
  };

  for (const entry of entries) {
    const p = entry.percentile;
    if (p >= 99) buckets.top_1 += 1;
    else if (p >= 95) buckets.top_5 += 1;
    else if (p >= 90) buckets.top_10 += 1;
    else if (p >= 75) buckets.top_25 += 1;
    else if (p >= 50) buckets.top_50 += 1;
    else buckets.rest += 1;
  }

  return buckets;
}

async function _cleanupOldSnapshots() {
  const now = new Date();
  const weeklyCutoff = new Date(now.getTime() - 56 * 24 * 60 * 60 * 1000);
  const monthlyCutoff = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
  const allTimeCutoff = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);

  const candidates = [];

  const weekly = await db
    .collection(COLLECTIONS.leaderboardSnapshots)
    .where("period", "==", "weekly")
    .where("generated_at", "<", Timestamp.fromDate(weeklyCutoff))
    .limit(100)
    .get();
  candidates.push(...weekly.docs);

  const monthly = await db
    .collection(COLLECTIONS.leaderboardSnapshots)
    .where("period", "==", "monthly")
    .where("generated_at", "<", Timestamp.fromDate(monthlyCutoff))
    .limit(100)
    .get();
  candidates.push(...monthly.docs);

  const allTime = await db
    .collection(COLLECTIONS.leaderboardSnapshots)
    .where("period", "==", "all_time")
    .where("generated_at", "<", Timestamp.fromDate(allTimeCutoff))
    .limit(100)
    .get();
  candidates.push(...allTime.docs);

  for (const snapshotDoc of candidates) {
    const snapshotId = snapshotDoc.id;

    const pages = await snapshotDoc.ref.collection("pages").get();
    for (const page of pages.docs) {
      await page.ref.delete();
    }

    while (true) {
      const entries = await db
        .collection(COLLECTIONS.rankingEntries)
        .where("snapshot_id", "==", snapshotId)
        .limit(500)
        .get();

      if (entries.empty) break;

      let batch = db.batch();
      let opCount = 0;
      for (const entry of entries.docs) {
        batch.delete(entry.ref);
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = db.batch();
          opCount = 0;
        }
      }
      if (opCount > 0) {
        await batch.commit();
      }
    }

    await snapshotDoc.ref.delete();
  }
}

async function _getLatestReadySnapshot({ metric, period, scopeType, scopeValue }) {
  const snap = await db
    .collection(COLLECTIONS.leaderboardSnapshots)
    .where("metric", "==", metric)
    .where("period", "==", period)
    .where("scope_type", "==", scopeType)
    .where("scope_value", "==", scopeValue)
    .where("status", "==", "ready")
    .orderBy("generated_at", "desc")
    .limit(1)
    .get();

  if (snap.empty) return null;
  return {
    id: snap.docs[0].id,
    ...snap.docs[0].data(),
  };
}

async function _loadQuestionsByIds(testType, questionIds) {
  const collection = testType === "iq" ? COLLECTIONS.iqQuestions : COLLECTIONS.eqQuestions;

  const uniqueIds = [...new Set(questionIds.filter((id) => typeof id === "string"))];
  const chunks = _chunk(uniqueIds, 30);
  const map = new Map();

  for (const chunkIds of chunks) {
    const snap = await db
      .collection(collection)
      .where(FieldPath.documentId(), "in", chunkIds)
      .get();

    snap.docs.forEach((doc) => {
      map.set(doc.id, doc.data());
    });
  }

  return map;
}

function _computeOfficialScore({ testType, questionIds, answers, questionMap, durationSeconds }) {
  if (testType === "iq") {
    return _computeIQScore({ questionIds, answers, questionMap, durationSeconds });
  }

  return _computeEQScore({ questionIds, answers, questionMap, durationSeconds });
}

function _computeIQScore({ questionIds, answers, questionMap, durationSeconds }) {
  let answered = 0;
  let rawCorrect = 0;
  let totalWeight = 0;
  let earnedWeight = 0;
  let difficultyTotal = 0;
  let difficultyCount = 0;

  const categoryTotals = {};
  const categoryEarned = {};

  for (const qid of questionIds) {
    const question = questionMap.get(qid);
    if (!question) continue;

    const answer = answers[qid];
    if (typeof answer !== "number") continue;
    answered++;

    const difficulty = Math.max(1, Math.min(5, Number(question.difficulty || 1)));
    const weight = 1 + (difficulty - 1) * 0.5;

    totalWeight += weight;
    difficultyTotal += difficulty;
    difficultyCount += 1;

    const category = question.category || "unknown";
    categoryTotals[category] = (categoryTotals[category] || 0) + weight;

    if (Number(question.correctAnswerIndex) === answer) {
      rawCorrect += 1;
      earnedWeight += weight;
      categoryEarned[category] = (categoryEarned[category] || 0) + weight;
    }
  }

  const rawAccuracy = answered > 0 ? rawCorrect / answered : 0;
  const weightedAccuracy = totalWeight > 0 ? earnedWeight / totalWeight : 0;

  const avgTimePerQuestion = answered > 0 ? durationSeconds / answered : durationSeconds;
  const timeFactor = _timeFactorIQ(avgTimePerQuestion);

  const normalizedPerformance = _clamp(weightedAccuracy * timeFactor, 0, 1);
  const iqScore = Math.round(55 + normalizedPerformance * 90);

  const categoryScores = {};
  Object.keys(categoryTotals).forEach((category) => {
    const earned = categoryEarned[category] || 0;
    const total = categoryTotals[category] || 1;
    categoryScores[category] = _round((earned / total) * 100, 1);
  });

  const difficultyAverage = difficultyCount > 0
    ? _round(difficultyTotal / difficultyCount, 3)
    : 1;

  return {
    score: iqScore,
    categoryScores,
    rawAccuracy: _round(rawAccuracy, 5),
    normalizedPerformance: _round(normalizedPerformance, 5),
    difficultyAverage,
    difficultyFactor: _round(difficultyAverage / 5, 5),
    percentileEstimate: _round(_estimatePercentileIQ(iqScore), 1),
  };
}

function _computeEQScore({ questionIds, answers, questionMap }) {
  const likertMin = 1;
  const likertMax = 5;

  let answered = 0;
  let earnedTotal = 0;
  let minTotal = 0;
  let maxTotal = 0;

  const categoryTotals = {};
  const categoryMin = {};
  const categoryMax = {};

  for (const qid of questionIds) {
    const question = questionMap.get(qid);
    if (!question) continue;

    const answer = answers[qid];
    if (typeof answer !== "number") continue;
    answered++;

    const weight = Number(question.weight || 1);
    const isReversed = Boolean(question.isReversed || question.is_reversed);
    const adjusted = isReversed
      ? (likertMax + likertMin) - answer
      : answer;

    const effective = adjusted * weight;
    const minimum = likertMin * weight;
    const maximum = likertMax * weight;

    earnedTotal += effective;
    minTotal += minimum;
    maxTotal += maximum;

    const category = question.category || "unknown";
    categoryTotals[category] = (categoryTotals[category] || 0) + effective;
    categoryMin[category] = (categoryMin[category] || 0) + minimum;
    categoryMax[category] = (categoryMax[category] || 0) + maximum;
  }

  const range = Math.max(1, maxTotal - minTotal);
  const normalized = _clamp((earnedTotal - minTotal) / range, 0, 1);
  const eqScore = _round(normalized * 100, 1);

  const categoryScores = {};
  Object.keys(categoryTotals).forEach((category) => {
    const catRange = Math.max(1, (categoryMax[category] || 0) - (categoryMin[category] || 0));
    const catNormalized = _clamp(
      ((categoryTotals[category] || 0) - (categoryMin[category] || 0)) / catRange,
      0,
      1,
    );
    categoryScores[category] = _round(catNormalized * 100, 1);
  });

  return {
    score: eqScore,
    categoryScores,
    rawAccuracy: _round(normalized, 5),
    normalizedPerformance: _round(normalized, 5),
    difficultyAverage: 1,
    difficultyFactor: 0.2,
    percentileEstimate: _round(_estimatePercentileEQ(eqScore), 1),
  };
}

async function _evaluateSuspicion({
  uid,
  testType,
  questionIds,
  answers,
  durationSeconds,
  answerHash,
  officialScore,
  deviceHash,
}) {
  const reasons = [];
  let riskScore = 0;

  const minDuration = questionIds.length * (SUSPICIOUS_SPEED_MIN_SECONDS[testType] || 3);
  if (durationSeconds > 0 && durationSeconds < minDuration) {
    reasons.push("impossibly_fast_completion");
    riskScore += 35;
  }

  const answeredCount = Object.keys(answers).length;
  if (answeredCount < Math.floor(questionIds.length * 0.7)) {
    reasons.push("insufficient_answer_coverage");
    riskScore += 20;
  }

  if (testType === "iq" && officialScore >= 144 && durationSeconds < questionIds.length * 5) {
    reasons.push("extreme_score_with_unusual_speed");
    riskScore += 25;
  }

  const repeatHashSnap = await db
    .collection(COLLECTIONS.testSessions)
    .where("userId", "==", uid)
    .where("answer_hash", "==", answerHash)
    .limit(3)
    .get();

  if (!repeatHashSnap.empty) {
    reasons.push("replayed_answer_pattern");
    riskScore += 20;
  }

  if (deviceHash) {
    const suspiciousDeviceSnap = await db
      .collection(COLLECTIONS.suspiciousSessions)
      .where("device_hash", "==", deviceHash)
      .where("status", "==", "pending_review")
      .limit(3)
      .get();

    if (suspiciousDeviceSnap.size >= 2) {
      reasons.push("high_risk_device_pattern");
      riskScore += 20;
    }
  }

  return {
    isSuspicious: riskScore >= 40,
    riskScore,
    reasons,
  };
}

function _deriveDisplayName(profile, user, uid) {
  const hide = profile && profile.hide_profile === true;
  const anonymous = profile && profile.anonymous_mode === true;

  const profileName = profile && typeof profile.display_name === "string"
    ? profile.display_name.trim()
    : "";
  const userName = user && typeof user.displayName === "string"
    ? user.displayName.trim()
    : "";

  let displayName = profileName || userName || `Lumoni-${uid.slice(0, 6)}`;
  if (anonymous) {
    const alias = profile && typeof profile.public_alias === "string"
      ? profile.public_alias.trim()
      : "";
    displayName = alias || `Anonymous-${uid.slice(0, 4)}`;
  }

  if (hide) {
    displayName = `Hidden-${uid.slice(0, 4)}`;
  }

  return _sanitizeDisplayName(displayName);
}

function _deriveVisibility(profile) {
  return {
    hideProfile: Boolean(profile && profile.hide_profile),
    anonymousMode: Boolean(profile && profile.anonymous_mode),
    visibilityScope: profile && typeof profile.visibility_scope === "string"
      ? profile.visibility_scope
      : "global",
    shareInCountry: profile && profile.share_in_country !== false,
  };
}

function _resolveCountryCode(profile, user) {
  const raw =
    (profile && profile.country_code) ||
    (user && user.countryCode) ||
    "US";
  return String(raw).trim().toUpperCase() || "US";
}

function _isVisibleInScope({ visibility, scopeType, countryCode, scopeValue }) {
  if (visibility.hideProfile) return false;

  if (visibility.visibilityScope === "private") {
    return false;
  }

  if (scopeType === "country") {
    if (!visibility.shareInCountry) return false;
    if (countryCode !== scopeValue) return false;
    if (visibility.visibilityScope === "global") return true;
    return visibility.visibilityScope === "country";
  }

  if (scopeType === "global") {
    return visibility.visibilityScope !== "country" || !visibility.shareInCountry;
  }

  return false;
}

function _normalizedValue(session, metric) {
  if (typeof session.normalizedPerformance === "number" && session.normalizedPerformance > 0) {
    return _clamp(session.normalizedPerformance, 0, 1);
  }

  if (metric === "iq") {
    return _clamp((session.score - 55) / 90, 0, 1);
  }

  return _clamp(session.score / 100, 0, 1);
}

function _timeFactorIQ(avgTimePerQuestion) {
  const bonusThreshold = 20;
  const penaltyThreshold = 45;

  if (avgTimePerQuestion <= 0) return 1;

  if (avgTimePerQuestion < bonusThreshold) {
    const bonus = 1 - (avgTimePerQuestion / bonusThreshold);
    return 1 + (bonus * 0.1);
  }

  if (avgTimePerQuestion > penaltyThreshold) {
    const excess = (avgTimePerQuestion - penaltyThreshold) / penaltyThreshold;
    return 1 - (_clamp(excess, 0, 1) * 0.05);
  }

  return 1;
}

function _estimatePercentileIQ(iqScore) {
  const z = (iqScore - 100) / 15;
  return _normalCDF(z) * 100;
}

function _estimatePercentileEQ(eqScore) {
  // Practical approximation for percentile display before aggregated distribution.
  return _clamp(eqScore, 1, 99);
}

function _normalCDF(z) {
  const t = 1 / (1 + 0.2316419 * Math.abs(z));
  const d = (1 / Math.sqrt(2 * Math.PI)) * Math.exp(-0.5 * z * z);
  const p = 1 - d * (
    0.319381530 * t +
    -0.356563782 * t * t +
    1.781477937 * Math.pow(t, 3) +
    -1.821255978 * Math.pow(t, 4) +
    1.330274429 * Math.pow(t, 5)
  );
  return z >= 0 ? p : 1 - p;
}

function _computeAnswerHash(testType, questionIds, answers) {
  const pairs = questionIds
    .map((id) => `${id}:${answers[id] ?? "x"}`)
    .join("|");

  return crypto
    .createHash("sha256")
    .update(`${testType}::${pairs}`)
    .digest("hex");
}

function _hashIp(ip) {
  if (!ip) return null;
  return crypto
    .createHash("sha256")
    .update(String(ip))
    .digest("hex");
}

function _sanitizeDisplayName(name) {
  if (!name || typeof name !== "string") {
    return "Lumoni User";
  }

  let sanitized = name.trim().replace(/\s+/g, " ");
  if (!sanitized) {
    return "Lumoni User";
  }

  const lowered = sanitized.toLowerCase();
  for (const blocked of MODERATION_BLOCKLIST) {
    if (lowered.includes(blocked)) {
      sanitized = "Lumoni User";
      break;
    }
  }

  if (sanitized.length > 24) {
    sanitized = sanitized.slice(0, 24);
  }

  return sanitized;
}

function _snapshotId({ metric, scopeType, scopeValue, period, now }) {
  const stamp = now.toISOString().replace(/[-:.TZ]/g, "").slice(0, 14);
  return `${metric}_${scopeType}_${scopeValue}_${period}_${stamp}`;
}

function _tierFromPercentile(percentile) {
  if (percentile >= 99) return "Legend";
  if (percentile >= 95) return "Diamond";
  if (percentile >= 85) return "Platinum";
  if (percentile >= 70) return "Gold";
  if (percentile >= 50) return "Silver";
  return "Bronze";
}

function _dateKey(date) {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function _parseTime(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value === "number") return new Date(value);
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function _chunk(values, size) {
  const chunks = [];
  for (let i = 0; i < values.length; i += size) {
    chunks.push(values.slice(i, i + size));
  }
  return chunks;
}

function _stdDev(values) {
  if (!values.length) return 0;
  const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
  const variance = values.reduce((sum, value) => {
    const diff = value - mean;
    return sum + diff * diff;
  }, 0) / values.length;
  return Math.sqrt(variance);
}

function _round(value, precision = 2) {
  const factor = 10 ** precision;
  return Math.round(value * factor) / factor;
}

function _clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function _asNumber(value) {
  return typeof value === "number" ? value : 0;
}
