/**
 * Lumoni Cloud Functions
 *
 * Firebase Cloud Functions for the Lumoni Intelligence Platform.
 * Handles IQ test generation, result calculation, and daily insights.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ─────────────────────────────────────────────────────────────────────────────
// Constants (mirror of AppConstants from the Flutter app)
// ─────────────────────────────────────────────────────────────────────────────

const IQ_CATEGORIES = ["pattern", "logical", "math", "verbal", "spatial"];
const MAX_IQ_QUESTIONS = 30;
const QUESTIONS_PER_CATEGORY = Math.ceil(MAX_IQ_QUESTIONS / IQ_CATEGORIES.length); // 6

const IQ_MEAN = 100.0;
const IQ_SD = 15.0;
const IQ_FLOOR = 55;
const IQ_CEILING = 145;

const TIME_BONUS_THRESHOLD = 20.0; // seconds per question
const MAX_TIME_BONUS = 0.10;
const TIME_PENALTY_THRESHOLD = 45.0;
const MAX_TIME_PENALTY = 0.05;

const RECENT_QUESTION_MEMORY = 200;
const TEST_DURATION_SECONDS = 15 * 60; // 15 minutes

const COLLECTIONS = {
  users: "users",
  iqQuestions: "iq_questions",
  eqQuestions: "eq_questions",
  testSessions: "test_sessions",
  results: "results",
};

// ─────────────────────────────────────────────────────────────────────────────
// 1. generateIQTest - HTTP Callable Function
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Generates a balanced, randomized IQ test for a user.
 *
 * Takes userId and difficulty level, queries Firestore for the user's recent
 * test sessions to get used question IDs, selects a balanced mix across all
 * five IQ categories, and adjusts difficulty based on previous scores.
 *
 * @param {string} data.userId - The ID of the user requesting the test.
 * @param {number} data.difficulty - Requested base difficulty (1-5). Defaults to 3.
 * @returns {Object} { questions: IQQuestion[], sessionId: string }
 */
exports.generateIQTest = onCall(
  { maxInstances: 50, region: "us-central1" },
  async (request) => {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const userId = request.data.userId || request.auth.uid;
    let difficulty = request.data.difficulty || 3;

    // Ensure the caller can only generate tests for themselves
    if (userId !== request.auth.uid) {
      throw new HttpsError(
        "permission-denied",
        "Cannot generate tests for another user."
      );
    }

    // Validate difficulty range
    difficulty = Math.max(1, Math.min(5, Math.round(difficulty)));

    try {
      // ── Step 1: Get recently used question IDs ──────────────────────────
      const recentSessionsSnap = await db
        .collection(COLLECTIONS.testSessions)
        .where("userId", "==", userId)
        .where("testType", "==", "iq")
        .orderBy("startedAt", "desc")
        .limit(10)
        .get();

      const recentQuestionIds = new Set();
      recentSessionsSnap.docs.forEach((doc) => {
        const data = doc.data();
        if (data.questionIds && Array.isArray(data.questionIds)) {
          data.questionIds.forEach((qId) => recentQuestionIds.add(qId));
        }
      });

      // Cap the exclusion set to avoid overly restricting the pool
      const exclusionSet = new Set(
        [...recentQuestionIds].slice(0, RECENT_QUESTION_MEMORY)
      );

      // ── Step 2: Adjust difficulty based on previous scores ──────────────
      const adjustedDifficulty = await _adjustDifficulty(userId, difficulty);

      // ── Step 3: Fetch questions per category ────────────────────────────
      const selectedQuestions = [];

      for (const category of IQ_CATEGORIES) {
        // Determine difficulty spread: primary difficulty + adjacent levels
        const difficultyLevels = _getDifficultySpread(adjustedDifficulty);

        let categoryQuestions = [];

        for (const diff of difficultyLevels) {
          if (categoryQuestions.length >= QUESTIONS_PER_CATEGORY) break;

          const remaining = QUESTIONS_PER_CATEGORY - categoryQuestions.length;
          // Fetch more than needed to allow filtering out exclusions
          const fetchLimit = remaining + Math.min(exclusionSet.size, 50);

          const snap = await db
            .collection(COLLECTIONS.iqQuestions)
            .where("category", "==", category)
            .where("difficulty", "==", diff)
            .limit(fetchLimit)
            .get();

          const filtered = snap.docs
            .filter((doc) => !exclusionSet.has(doc.id))
            .filter(
              (doc) =>
                !categoryQuestions.some((q) => q.id === doc.id)
            );

          // Shuffle and take what we need
          _shuffle(filtered);
          const toTake = Math.min(remaining, filtered.length);

          for (let i = 0; i < toTake; i++) {
            const doc = filtered[i];
            const data = doc.data();
            categoryQuestions.push({
              id: doc.id,
              question: data.question,
              imageUrl: data.imageUrl || null,
              answers: data.answers,
              correctAnswerIndex: data.correctAnswerIndex,
              difficulty: data.difficulty,
              category: data.category,
              explanation: data.explanation || "",
            });
          }
        }

        selectedQuestions.push(...categoryQuestions);
      }

      // ── Step 4: Handle shortfall by filling from any category ───────────
      if (selectedQuestions.length < MAX_IQ_QUESTIONS) {
        const existingIds = new Set(selectedQuestions.map((q) => q.id));
        const combinedExclusion = new Set([...exclusionSet, ...existingIds]);

        const fillSnap = await db
          .collection(COLLECTIONS.iqQuestions)
          .limit(MAX_IQ_QUESTIONS - selectedQuestions.length + combinedExclusion.size)
          .get();

        const fillDocs = fillSnap.docs.filter(
          (doc) => !combinedExclusion.has(doc.id)
        );

        _shuffle(fillDocs);

        const needed = MAX_IQ_QUESTIONS - selectedQuestions.length;
        for (let i = 0; i < Math.min(needed, fillDocs.length); i++) {
          const doc = fillDocs[i];
          const data = doc.data();
          selectedQuestions.push({
            id: doc.id,
            question: data.question,
            imageUrl: data.imageUrl || null,
            answers: data.answers,
            correctAnswerIndex: data.correctAnswerIndex,
            difficulty: data.difficulty,
            category: data.category,
            explanation: data.explanation || "",
          });
        }
      }

      // ── Step 5: Trim to exact count and shuffle final order ─────────────
      const finalQuestions = selectedQuestions.slice(0, MAX_IQ_QUESTIONS);
      _shuffle(finalQuestions);

      // ── Step 6: Create a pending test session ───────────────────────────
      const sessionRef = db.collection(COLLECTIONS.testSessions).doc();
      await sessionRef.set({
        userId: userId,
        testType: "iq",
        startedAt: Timestamp.now(),
        completedAt: null,
        score: null,
        categoryScores: {},
        questionIds: finalQuestions.map((q) => q.id),
        answers: {},
        timeSpentSeconds: 0,
      });

      return {
        questions: finalQuestions,
        sessionId: sessionRef.id,
        totalQuestions: finalQuestions.length,
        adjustedDifficulty: adjustedDifficulty,
      };
    } catch (error) {
      console.error("generateIQTest error:", error);
      throw new HttpsError(
        "internal",
        "Failed to generate IQ test. Please try again.",
        error.message
      );
    }
  }
);

/**
 * Adjusts difficulty based on the user's recent IQ test scores.
 *
 * - If last score >= 120: increase difficulty by 1
 * - If last score >= 110: keep as-is
 * - If last score < 90: decrease difficulty by 1
 * - If last score < 80: decrease difficulty by 2
 *
 * @param {string} userId
 * @param {number} baseDifficulty - The user-requested difficulty (1-5).
 * @returns {number} Adjusted difficulty clamped between 1 and 5.
 */
async function _adjustDifficulty(userId, baseDifficulty) {
  try {
    const recentResults = await db
      .collection(COLLECTIONS.testSessions)
      .where("userId", "==", userId)
      .where("testType", "==", "iq")
      .where("completedAt", "!=", null)
      .orderBy("completedAt", "desc")
      .limit(3)
      .get();

    if (recentResults.empty) return baseDifficulty;

    // Calculate average of recent scores
    let totalScore = 0;
    let count = 0;
    recentResults.docs.forEach((doc) => {
      const score = doc.data().score;
      if (score != null) {
        totalScore += score;
        count++;
      }
    });

    if (count === 0) return baseDifficulty;

    const avgScore = totalScore / count;

    let adjustment = 0;
    if (avgScore >= 130) adjustment = 2;
    else if (avgScore >= 120) adjustment = 1;
    else if (avgScore >= 110) adjustment = 0;
    else if (avgScore >= 90) adjustment = 0;
    else if (avgScore >= 80) adjustment = -1;
    else adjustment = -2;

    const adjusted = baseDifficulty + adjustment;
    return Math.max(1, Math.min(5, adjusted));
  } catch (error) {
    console.warn("_adjustDifficulty fallback:", error.message);
    return baseDifficulty;
  }
}

/**
 * Returns an array of difficulty levels to query, starting from the primary
 * difficulty and including adjacent levels for variety.
 *
 * Example: difficulty 3 -> [3, 2, 4, 1, 5]
 */
function _getDifficultySpread(primary) {
  const levels = [primary];
  for (let offset = 1; offset <= 4; offset++) {
    if (primary - offset >= 1) levels.push(primary - offset);
    if (primary + offset <= 5) levels.push(primary + offset);
  }
  return levels;
}

/**
 * Fisher-Yates in-place shuffle.
 */
function _shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. calculateAndSaveResults - Firestore Trigger
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Triggered when a test_sessions document is written (created or updated).
 *
 * When a session is completed (completedAt becomes non-null):
 * 1. Calculates the normalized IQ score from raw answers.
 * 2. Computes per-category scores.
 * 3. Updates the user's aggregate stats (highestIQ, totalIQTests, etc.).
 * 4. Saves detailed results to the results collection.
 */
exports.calculateAndSaveResults = onDocumentWritten(
  { document: "test_sessions/{sessionId}", region: "us-central1" },
  async (event) => {
    const beforeData = event.data.before?.data();
    const afterData = event.data.after?.data();

    // Only process when a session transitions to completed
    if (!afterData) return; // Document was deleted
    if (!afterData.completedAt) return; // Not yet completed
    if (beforeData && beforeData.completedAt) return; // Already was completed

    const sessionId = event.params.sessionId;
    const testType = afterData.testType;
    const userId = afterData.userId;
    const answers = afterData.answers || {};
    const questionIds = afterData.questionIds || [];
    const timeSpentSeconds = afterData.timeSpentSeconds || 0;

    try {
      if (testType === "iq") {
        await _processIQResult(sessionId, userId, questionIds, answers, timeSpentSeconds);
      } else if (testType === "eq") {
        await _processEQResult(sessionId, userId, questionIds, answers, timeSpentSeconds);
      }
    } catch (error) {
      console.error(`calculateAndSaveResults error for session ${sessionId}:`, error);
    }
  }
);

/**
 * Processes and scores a completed IQ test session.
 */
async function _processIQResult(sessionId, userId, questionIds, answers, timeSpentSeconds) {
  // Fetch all questions for this session
  const questions = [];
  for (const qId of questionIds) {
    const qDoc = await db.collection(COLLECTIONS.iqQuestions).doc(qId).get();
    if (qDoc.exists) {
      questions.push({ id: qDoc.id, ...qDoc.data() });
    }
  }

  if (questions.length === 0) {
    console.warn(`No questions found for session ${sessionId}`);
    return;
  }

  // ── Calculate raw score ──────────────────────────────────────────────────
  let totalCorrect = 0;
  let totalWeightedScore = 0;
  const categoryCorrect = {};
  const categoryTotal = {};

  IQ_CATEGORIES.forEach((cat) => {
    categoryCorrect[cat] = 0;
    categoryTotal[cat] = 0;
  });

  for (let i = 0; i < questions.length; i++) {
    const question = questions[i];
    const answerKey = i.toString();
    const questionIdKey = question.id;

    // Try both index-based and id-based answer keys
    const userAnswer = answers[answerKey] ?? answers[questionIdKey] ?? null;

    const category = question.category;
    categoryTotal[category] = (categoryTotal[category] || 0) + 1;

    if (userAnswer != null && userAnswer === question.correctAnswerIndex) {
      totalCorrect++;
      categoryCorrect[category] = (categoryCorrect[category] || 0) + 1;

      // Weighted scoring: harder questions are worth more
      const difficultyWeight = 0.5 + question.difficulty * 0.25;
      totalWeightedScore += difficultyWeight;
    }
  }

  // ── Time adjustment ──────────────────────────────────────────────────────
  const avgTimePerQuestion =
    questions.length > 0 ? timeSpentSeconds / questions.length : 30;

  let timeFactor = 1.0;
  if (avgTimePerQuestion < TIME_BONUS_THRESHOLD) {
    const bonusFraction =
      ((TIME_BONUS_THRESHOLD - avgTimePerQuestion) / TIME_BONUS_THRESHOLD) *
      MAX_TIME_BONUS;
    timeFactor = 1.0 + bonusFraction;
  } else if (avgTimePerQuestion > TIME_PENALTY_THRESHOLD) {
    const penaltyFraction =
      ((avgTimePerQuestion - TIME_PENALTY_THRESHOLD) / TIME_PENALTY_THRESHOLD) *
      MAX_TIME_PENALTY;
    timeFactor = 1.0 - Math.min(penaltyFraction, MAX_TIME_PENALTY);
  }

  // ── Normalize to IQ scale ────────────────────────────────────────────────
  const maxWeightedScore = questions.reduce(
    (sum, q) => sum + (0.5 + q.difficulty * 0.25),
    0
  );

  const rawFraction =
    maxWeightedScore > 0 ? totalWeightedScore / maxWeightedScore : 0;
  const adjustedFraction = rawFraction * timeFactor;

  // Map fraction to IQ scale using z-score transformation
  // raw 0.5 maps to mean (100), with spread based on SD
  const zScore = (adjustedFraction - 0.5) / 0.18;
  let iqScore = Math.round(IQ_MEAN + zScore * IQ_SD);
  iqScore = Math.max(IQ_FLOOR, Math.min(IQ_CEILING, iqScore));

  // ── Category scores (percentage correct) ─────────────────────────────────
  const categoryScores = {};
  for (const cat of IQ_CATEGORIES) {
    if (categoryTotal[cat] > 0) {
      categoryScores[cat] = Math.round(
        (categoryCorrect[cat] / categoryTotal[cat]) * 100
      );
    } else {
      categoryScores[cat] = 0;
    }
  }

  // ── Determine classification ─────────────────────────────────────────────
  let classification;
  if (iqScore >= 130) classification = "Exceptionally High";
  else if (iqScore >= 115) classification = "Above Average";
  else if (iqScore >= 85) classification = "Average";
  else if (iqScore >= 70) classification = "Below Average";
  else classification = "Low";

  // ── Save detailed result ─────────────────────────────────────────────────
  const resultData = {
    sessionId: sessionId,
    userId: userId,
    testType: "iq",
    iqScore: iqScore,
    classification: classification,
    totalCorrect: totalCorrect,
    totalQuestions: questions.length,
    accuracy: questions.length > 0 ? totalCorrect / questions.length : 0,
    categoryScores: categoryScores,
    timeSpentSeconds: timeSpentSeconds,
    avgTimePerQuestion: Math.round(avgTimePerQuestion * 10) / 10,
    timeFactor: Math.round(timeFactor * 1000) / 1000,
    createdAt: Timestamp.now(),
  };

  await db.collection(COLLECTIONS.results).doc(sessionId).set(resultData);

  // ── Update the session document with the computed score ──────────────────
  await db.collection(COLLECTIONS.testSessions).doc(sessionId).update({
    score: iqScore,
    categoryScores: categoryScores,
  });

  // ── Update user aggregate stats ──────────────────────────────────────────
  const userRef = db.collection(COLLECTIONS.users).doc(userId);
  const userDoc = await userRef.get();

  if (userDoc.exists) {
    const userData = userDoc.data();
    const currentHighest = userData.highestIQ || 0;
    const currentTotal = userData.totalIQTests || 0;

    const updates = {
      totalIQTests: currentTotal + 1,
      lastTestAt: Timestamp.now(),
    };

    if (iqScore > currentHighest) {
      updates.highestIQ = iqScore;
    }

    await userRef.update(updates);
  }
}

/**
 * Processes and scores a completed EQ test session.
 */
async function _processEQResult(sessionId, userId, questionIds, answers, timeSpentSeconds) {
  // Fetch all EQ statements for this session
  const statements = [];
  for (const qId of questionIds) {
    const qDoc = await db.collection(COLLECTIONS.eqQuestions).doc(qId).get();
    if (qDoc.exists) {
      statements.push({ id: qDoc.id, ...qDoc.data() });
    }
  }

  if (statements.length === 0) {
    console.warn(`No EQ statements found for session ${sessionId}`);
    return;
  }

  const EQ_CATEGORIES = [
    "selfAwareness",
    "selfRegulation",
    "motivation",
    "empathy",
    "socialSkills",
  ];

  const LIKERT_MIN = 1;
  const LIKERT_MAX = 5;

  // ── Calculate category scores ────────────────────────────────────────────
  const categoryTotals = {};
  const categoryCounts = {};

  EQ_CATEGORIES.forEach((cat) => {
    categoryTotals[cat] = 0;
    categoryCounts[cat] = 0;
  });

  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];
    const answerKey = statement.id;
    const indexKey = i.toString();

    const rawResponse = answers[answerKey] ?? answers[indexKey];
    if (rawResponse == null) continue;

    let effectiveValue = rawResponse;
    if (statement.isReversed) {
      effectiveValue = LIKERT_MAX + LIKERT_MIN - rawResponse;
    }

    const weight = statement.weight || 1.0;
    const category = statement.category;

    categoryTotals[category] = (categoryTotals[category] || 0) + effectiveValue * weight;
    categoryCounts[category] = (categoryCounts[category] || 0) + weight;
  }

  // Normalize to 0-100 scale
  const categoryScores = {};
  let overallTotal = 0;
  let overallCount = 0;

  for (const cat of EQ_CATEGORIES) {
    if (categoryCounts[cat] > 0) {
      const rawAvg = categoryTotals[cat] / categoryCounts[cat];
      // Map from Likert range [1, 5] to [0, 100]
      categoryScores[cat] = Math.round(
        ((rawAvg - LIKERT_MIN) / (LIKERT_MAX - LIKERT_MIN)) * 100
      );
      overallTotal += categoryScores[cat];
      overallCount++;
    } else {
      categoryScores[cat] = 0;
    }
  }

  const overallScore =
    overallCount > 0 ? Math.round(overallTotal / overallCount) : 0;

  // ── Determine classification ─────────────────────────────────────────────
  let classification;
  if (overallScore >= 80) classification = "Exceptional";
  else if (overallScore >= 60) classification = "Strong";
  else if (overallScore >= 40) classification = "Developing";
  else if (overallScore >= 20) classification = "Emerging";
  else classification = "Needs Improvement";

  // ── Save detailed result ─────────────────────────────────────────────────
  const resultData = {
    sessionId: sessionId,
    userId: userId,
    testType: "eq",
    overallScore: overallScore,
    classification: classification,
    categoryScores: categoryScores,
    totalStatements: statements.length,
    timeSpentSeconds: timeSpentSeconds,
    createdAt: Timestamp.now(),
  };

  await db.collection(COLLECTIONS.results).doc(sessionId).set(resultData);

  // ── Update the session document ──────────────────────────────────────────
  await db.collection(COLLECTIONS.testSessions).doc(sessionId).update({
    score: overallScore,
    categoryScores: categoryScores,
  });

  // ── Update user aggregate stats ──────────────────────────────────────────
  const userRef = db.collection(COLLECTIONS.users).doc(userId);
  const userDoc = await userRef.get();

  if (userDoc.exists) {
    const userData = userDoc.data();
    const currentTotal = userData.totalEQTests || 0;
    const currentAvg = userData.averageEQ || 0;

    const newTotal = currentTotal + 1;
    const newAvg =
      currentTotal > 0
        ? (currentAvg * currentTotal + overallScore) / newTotal
        : overallScore;

    await userRef.update({
      totalEQTests: newTotal,
      averageEQ: Math.round(newAvg * 10) / 10,
      lastTestAt: Timestamp.now(),
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. generateDailyInsight - Scheduled Function
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Runs daily at 6:00 AM UTC. Selects a random insight for each active user
 * and stores it in the user's daily_insights subcollection.
 *
 * Insights rotate through brain science, IQ, EQ, performance, and mindset
 * categories. Users who have been active in the last 30 days receive a new
 * daily insight.
 */
exports.generateDailyInsight = onSchedule(
  {
    schedule: "every day 06:00",
    timeZone: "UTC",
    region: "us-central1",
    retryCount: 3,
  },
  async (event) => {
    try {
      // Find active users (active in last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const activeUsersSnap = await db
        .collection(COLLECTIONS.users)
        .where("lastTestAt", ">=", Timestamp.fromDate(thirtyDaysAgo))
        .get();

      // Also include users created in last 30 days who may not have tested yet
      const newUsersSnap = await db
        .collection(COLLECTIONS.users)
        .where("createdAt", ">=", Timestamp.fromDate(thirtyDaysAgo))
        .get();

      // Merge unique user IDs
      const userIds = new Set();
      activeUsersSnap.docs.forEach((doc) => userIds.add(doc.id));
      newUsersSnap.docs.forEach((doc) => userIds.add(doc.id));

      if (userIds.size === 0) {
        console.log("No active users found for daily insights.");
        return;
      }

      const today = new Date();
      const dateStr = today.toISOString().split("T")[0]; // e.g., "2026-03-04"

      // Use day-of-year as a base index for rotating insights
      const startOfYear = new Date(today.getFullYear(), 0, 0);
      const diff = today - startOfYear;
      const dayOfYear = Math.floor(diff / (1000 * 60 * 60 * 24));

      const batch = db.batch();
      let batchCount = 0;
      const MAX_BATCH_SIZE = 450; // Firestore batch limit is 500

      for (const userId of userIds) {
        // Each user gets a slightly different insight based on their userId hash
        const userHash = _simpleHash(userId);
        const insightIndex = (dayOfYear + userHash) % DAILY_INSIGHTS.length;
        const insight = DAILY_INSIGHTS[insightIndex];

        const insightRef = db
          .collection(COLLECTIONS.users)
          .doc(userId)
          .collection("daily_insights")
          .doc(dateStr);

        batch.set(insightRef, {
          title: insight.title,
          description: insight.description,
          category: insight.category,
          icon: insight.icon,
          date: dateStr,
          createdAt: Timestamp.now(),
        });

        batchCount++;

        // Commit in chunks if approaching batch limit
        if (batchCount >= MAX_BATCH_SIZE) {
          await batch.commit();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      console.log(`Daily insights generated for ${userIds.size} users.`);
    } catch (error) {
      console.error("generateDailyInsight error:", error);
      throw error;
    }
  }
);

/**
 * Simple string hash function for deterministic per-user variation.
 */
function _simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash);
}

/**
 * Daily insights data (mirrors DailyInsight.insights from the Flutter app).
 * Icon names use Material Icons identifiers for mapping on the client.
 */
const DAILY_INSIGHTS = [
  // Brain Science
  {
    title: "Your Brain Never Stops",
    description:
      "Your brain generates about 70,000 thoughts per day and uses 20% of your body's total energy, even though it's only 2% of your body weight.",
    category: "Brain Science",
    icon: "psychology",
  },
  {
    title: "Neuroplasticity Is Real",
    description:
      "Your brain can rewire itself at any age. Every time you learn something new, you physically change the structure of your brain by forming new neural connections.",
    category: "Brain Science",
    icon: "hub",
  },
  {
    title: "Sleep Powers Intelligence",
    description:
      "During deep sleep, your brain consolidates memories and clears toxic waste products. Just one night of poor sleep can reduce cognitive performance by up to 30%.",
    category: "Brain Science",
    icon: "nightlight_round",
  },
  {
    title: "The Mozart Effect",
    description:
      "While listening to classical music doesn't permanently raise IQ, it can temporarily improve spatial-temporal reasoning and boost focus during complex tasks.",
    category: "Brain Science",
    icon: "music_note",
  },
  {
    title: "Brain Speed",
    description:
      "Information travels through your neurons at speeds up to 268 mph. That's faster than a Formula 1 car. Your brain processes images in as little as 13 milliseconds.",
    category: "Brain Science",
    icon: "speed",
  },
  {
    title: "The Reading Brain",
    description:
      "Reading physically changes your brain. Regular readers show increased connectivity in the left temporal cortex, the area associated with language comprehension.",
    category: "Brain Science",
    icon: "auto_stories",
  },
  {
    title: "The Creativity Connection",
    description:
      "Creativity and intelligence share neural networks but are not identical. Daydreaming activates the brain's default mode network, which is essential for creative problem-solving.",
    category: "Brain Science",
    icon: "palette",
  },

  // IQ & Cognitive Performance
  {
    title: "IQ Is Not Fixed",
    description:
      "Research shows that IQ scores can change by up to 20 points over a lifetime. Education, mental challenges, and a stimulating environment all contribute to cognitive growth.",
    category: "IQ",
    icon: "trending_up",
  },
  {
    title: "Practice Makes Permanent",
    description:
      "Deliberate practice on cognitive tasks can strengthen specific neural pathways. The more you challenge your pattern recognition, the sharper it becomes.",
    category: "IQ",
    icon: "fitness_center",
  },
  {
    title: "The Power of Curiosity",
    description:
      "Curious people tend to score higher on intelligence tests. Curiosity activates the brain's reward system and enhances memory formation for new information.",
    category: "IQ",
    icon: "lightbulb",
  },
  {
    title: "Working Memory Matters",
    description:
      "Working memory, your ability to hold and manipulate information, is one of the strongest predictors of fluid intelligence. It can be trained through targeted exercises.",
    category: "IQ",
    icon: "memory",
  },
  {
    title: "The Testing Effect",
    description:
      "Taking tests actually improves learning more than additional study time. Each test you complete strengthens the neural pathways for recall and problem-solving.",
    category: "IQ",
    icon: "quiz",
  },
  {
    title: "Fluid vs. Crystallized",
    description:
      "Fluid intelligence (problem-solving) peaks in your 20s, but crystallized intelligence (accumulated knowledge) continues growing well into your 60s and 70s.",
    category: "IQ",
    icon: "diamond",
  },
  {
    title: "Bilingual Advantage",
    description:
      "People who speak two or more languages show enhanced executive function, better attention control, and delayed cognitive decline in older age.",
    category: "IQ",
    icon: "translate",
  },

  // Emotional Intelligence
  {
    title: "EQ Predicts Success",
    description:
      "Studies show that emotional intelligence accounts for up to 58% of job performance across all types of careers. It's often a stronger predictor of success than IQ alone.",
    category: "EQ",
    icon: "favorite",
  },
  {
    title: "Emotions Are Data",
    description:
      "Your emotions are information signals from your brain. Learning to read and interpret them accurately is a core skill of emotional intelligence that can be developed over time.",
    category: "EQ",
    icon: "analytics",
  },
  {
    title: "The Empathy Muscle",
    description:
      "Empathy is like a muscle that gets stronger with use. Actively practicing perspective-taking can increase activity in your brain's empathy circuits within weeks.",
    category: "EQ",
    icon: "people",
  },
  {
    title: "Name It to Tame It",
    description:
      "Simply labeling your emotions reduces amygdala activation by up to 50%. The more specific you can be about what you feel, the better you can regulate your response.",
    category: "EQ",
    icon: "label",
  },
  {
    title: "Emotional Contagion",
    description:
      "Emotions are literally contagious. Mirror neurons in your brain cause you to unconsciously mimic the emotions of those around you. Awareness of this is key to self-regulation.",
    category: "EQ",
    icon: "group",
  },
  {
    title: "The 90-Second Rule",
    description:
      "The chemical process of any emotion lasts only about 90 seconds. After that, any remaining emotional response is caused by you choosing to stay in that emotional loop.",
    category: "EQ",
    icon: "timer",
  },
  {
    title: "Self-Awareness First",
    description:
      "Self-awareness is the foundation of all emotional intelligence. People who regularly reflect on their emotions make better decisions and build stronger relationships.",
    category: "EQ",
    icon: "self_improvement",
  },
  {
    title: "Social Intelligence",
    description:
      "Strong social connections are linked to better cognitive function and slower cognitive decline. Meaningful conversations challenge your brain in ways that solitary activities cannot.",
    category: "EQ",
    icon: "connect_without_contact",
  },

  // Productivity & Performance
  {
    title: "The 20-Minute Rule",
    description:
      "It takes an average of 23 minutes to refocus after a distraction. Protecting your focus time is one of the most effective ways to maximize cognitive performance.",
    category: "Performance",
    icon: "timer_outlined",
  },
  {
    title: "Exercise Boosts IQ",
    description:
      "Regular aerobic exercise increases the size of the hippocampus, improving memory and learning. Just 30 minutes of exercise can boost cognitive performance for hours afterward.",
    category: "Performance",
    icon: "directions_run",
  },
  {
    title: "The Power of Breaks",
    description:
      "Strategic breaks during mental work improve focus and creativity. The Pomodoro technique (25 min work, 5 min break) aligns with your brain's natural attention cycles.",
    category: "Performance",
    icon: "coffee",
  },
  {
    title: "Hydration & Cognition",
    description:
      "Even mild dehydration (1-2% body weight loss) can impair attention, memory, and mood. Staying hydrated is one of the simplest ways to maintain peak mental performance.",
    category: "Performance",
    icon: "water_drop",
  },
  {
    title: "Meditation Changes the Brain",
    description:
      "Just 8 weeks of regular meditation can increase gray matter density in brain regions linked to memory, empathy, and stress regulation. Even 10 minutes daily makes a difference.",
    category: "Performance",
    icon: "spa",
  },
  {
    title: "The Spacing Effect",
    description:
      "Spreading learning over time (spaced repetition) is far more effective than cramming. Your brain consolidates information better when given time between study sessions.",
    category: "Performance",
    icon: "calendar_today",
  },
  {
    title: "Your Brain on Nature",
    description:
      "Spending just 20 minutes in nature reduces cortisol levels and improves working memory. Natural environments give your brain's directed attention circuits a chance to rest and recharge.",
    category: "Performance",
    icon: "park",
  },

  // Mindset & Growth
  {
    title: "Growth Mindset Wins",
    description:
      "People who believe intelligence can be developed (growth mindset) outperform those who think it's fixed. Your beliefs about your own ability literally shape your brain.",
    category: "Mindset",
    icon: "rocket_launch",
  },
  {
    title: "Embrace the Struggle",
    description:
      "The feeling of cognitive struggle is actually a sign of learning. When a problem feels hard, your brain is building new connections. Discomfort is where growth happens.",
    category: "Mindset",
    icon: "bolt",
  },
  {
    title: "Failure Is Fertilizer",
    description:
      "Your brain learns more from mistakes than from successes. Error signals trigger stronger neural encoding, making failures some of your most valuable learning experiences.",
    category: "Mindset",
    icon: "eco",
  },
  {
    title: "The Power of Yet",
    description:
      'Adding the word "yet" to negative self-talk transforms it. "I can\'t solve this" becomes "I can\'t solve this yet." This simple shift activates growth-oriented thinking.',
    category: "Mindset",
    icon: "auto_awesome",
  },
  {
    title: "Teach to Learn",
    description:
      "Explaining concepts to others is one of the most effective learning strategies. Teaching forces your brain to organize knowledge more deeply and identify gaps in understanding.",
    category: "Mindset",
    icon: "school",
  },
];
