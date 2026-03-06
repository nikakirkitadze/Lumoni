/// App-wide constants for the Lumoni intelligence platform.
abstract final class AppConstants {
  // ──────────────────────── App Info ────────────────────────────────────
  static const String appName = 'Lumoni';
  static const String appTagline = 'Premium Intelligence Platform';
  static const String supportEmail = 'support@lumoni.app';
  static const String privacyPolicyUrl = 'https://lumoni.app/privacy';
  static const String termsOfServiceUrl = 'https://lumoni.app/terms';

  // ──────────────────────── Test Configuration ─────────────────────────
  /// Maximum duration for a single test session in minutes.
  static const int testDurationMinutes = 15;

  /// Maximum duration in seconds (derived).
  static const int testDurationSeconds = testDurationMinutes * 60;

  /// Maximum number of questions per IQ test session.
  static const int maxIQQuestions = 30;

  /// Maximum number of questions per EQ test session.
  static const int maxEQQuestions = 40;

  /// Number of free tests allowed before paywall.
  static const int freeTestLimit = 3;

  /// Minimum number of questions required for a valid test result.
  static const int minQuestionsForValidResult = 10;

  /// Cooldown period between tests in hours.
  static const int testCooldownHours = 1;

  // ──────────────────────── IQ Scoring ─────────────────────────────────
  /// Population mean for IQ normalization.
  static const double iqMean = 100.0;

  /// Population standard deviation for IQ normalization.
  static const double iqStandardDeviation = 15.0;

  /// Minimum possible IQ score (floor).
  static const int iqScoreFloor = 55;

  /// Maximum possible IQ score (ceiling).
  static const int iqScoreCeiling = 145;

  /// Time bonus threshold - answering faster than this (in seconds per
  /// question) earns a bonus.
  static const double timeBonusThresholdSeconds = 20.0;

  /// Maximum time bonus applied to raw score (as a fraction, e.g. 0.10 = 10%).
  static const double maxTimeBonusFraction = 0.10;

  /// Time penalty threshold - answering slower than this (in seconds per
  /// question) incurs a penalty.
  static const double timePenaltyThresholdSeconds = 45.0;

  /// Maximum time penalty applied to raw score (as a fraction).
  static const double maxTimePenaltyFraction = 0.05;

  // ──────────────────────── EQ Scoring ─────────────────────────────────
  /// Likert scale minimum value.
  static const int likertMin = 1;

  /// Likert scale maximum value.
  static const int likertMax = 5;

  /// Maximum possible EQ category score.
  static const double eqMaxCategoryScore = 100.0;

  /// Minimum possible EQ category score.
  static const double eqMinCategoryScore = 0.0;

  // ──────────────────────── IQ Categories ──────────────────────────────
  static const List<String> iqCategories = [
    iqCategoryPattern,
    iqCategoryLogical,
    iqCategoryMath,
    iqCategoryVerbal,
    iqCategorySpatial,
  ];

  static const String iqCategoryPattern = 'pattern';
  static const String iqCategoryLogical = 'logical';
  static const String iqCategoryMath = 'math';
  static const String iqCategoryVerbal = 'verbal';
  static const String iqCategorySpatial = 'spatial';

  /// Human-readable labels for IQ categories.
  static const Map<String, String> iqCategoryLabels = {
    iqCategoryPattern: 'Pattern Recognition',
    iqCategoryLogical: 'Logical Reasoning',
    iqCategoryMath: 'Mathematical Ability',
    iqCategoryVerbal: 'Verbal Intelligence',
    iqCategorySpatial: 'Spatial Reasoning',
  };

  // ──────────────────────── EQ Categories ──────────────────────────────
  static const List<String> eqCategories = [
    eqCategorySelfAwareness,
    eqCategorySelfRegulation,
    eqCategoryMotivation,
    eqCategoryEmpathy,
    eqCategorySocialSkills,
  ];

  static const String eqCategorySelfAwareness = 'selfAwareness';
  static const String eqCategorySelfRegulation = 'selfRegulation';
  static const String eqCategoryMotivation = 'motivation';
  static const String eqCategoryEmpathy = 'empathy';
  static const String eqCategorySocialSkills = 'socialSkills';

  /// Human-readable labels for EQ categories.
  static const Map<String, String> eqCategoryLabels = {
    eqCategorySelfAwareness: 'Self-Awareness',
    eqCategorySelfRegulation: 'Self-Regulation',
    eqCategoryMotivation: 'Motivation',
    eqCategoryEmpathy: 'Empathy',
    eqCategorySocialSkills: 'Social Skills',
  };

  // ──────────────────────── IQ Classification ──────────────────────────
  /// IQ score ranges and their classifications.
  static const Map<String, (int, int)> iqClassifications = {
    'Exceptionally High': (130, 145),
    'Above Average': (115, 129),
    'Average': (85, 114),
    'Below Average': (70, 84),
    'Low': (55, 69),
  };

  /// Returns the IQ classification label for a given score.
  static String iqClassification(int score) {
    if (score >= 130) return 'Exceptionally High';
    if (score >= 115) return 'Above Average';
    if (score >= 85) return 'Average';
    if (score >= 70) return 'Below Average';
    return 'Low';
  }

  // ──────────────────────── EQ Classification ──────────────────────────
  /// Returns the EQ classification label for a given overall score (0-100).
  static String eqClassification(double score) {
    if (score >= 80) return 'Exceptional';
    if (score >= 60) return 'Strong';
    if (score >= 40) return 'Developing';
    if (score >= 20) return 'Emerging';
    return 'Needs Improvement';
  }

  // ──────────────────────── Difficulty Levels ──────────────────────────
  static const int difficultyMin = 1;
  static const int difficultyMax = 5;

  static const Map<int, String> difficultyLabels = {
    1: 'Very Easy',
    2: 'Easy',
    3: 'Medium',
    4: 'Hard',
    5: 'Very Hard',
  };

  // ──────────────────────── Question Selection ─────────────────────────
  /// Number of recently used question IDs to track for avoidance.
  static const int recentQuestionMemorySize = 200;

  /// Target number of questions per category in a balanced test.
  static int questionsPerCategory(int totalQuestions, int categoryCount) =>
      (totalQuestions / categoryCount).ceil();

  // ──────────────────────── Firestore Collections ──────────────────────
  static const String usersCollection = 'users';
  static const String iqQuestionsCollection = 'iq_questions';
  static const String eqQuestionsCollection = 'eq_questions';
  static const String testSessionsCollection = 'test_sessions';
  static const String resultsCollection = 'results';

  // ──────────────────────── Hive Box Names ─────────────────────────────
  static const String preferencesBox = 'preferences';
  static const String cacheBox = 'cache';
  static const String questionHistoryBox = 'question_history';

  // ──────────────────────── Hive Keys ──────────────────────────────────
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyLastTestDate = 'last_test_date';
  static const String keyCachedIQScore = 'cached_iq_score';
  static const String keyCachedEQScore = 'cached_eq_score';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyRecentQuestionIds = 'recent_question_ids';
  static const String keyFreeTestsUsed = 'free_tests_used';
  static const String keyUserId = 'user_id';
  static const String keyPendingEmailLink = 'pending_email_link';

  // ──────────────────────── RevenueCat ─────────────────────────────────
  static const String revenueCatApiKeyiOS = 'appl_itgsGuluiUYSCOQtkfycoquqnyj';
  static const String revenueCatApiKeyAndroid =
      'test_GSfkyrdZGBxZOPhfGEEcCynVYLN';
  static const String premiumEntitlementId = 'Lumoni Pro';
  static const String monthlyProductId = 'monthly';
  static const String yearlyProductId = 'yearly';
  static const String lifetimeProductId = 'lumoni_pro_lifetime';

  // ──────────────────────── Animation Durations ────────────────────────
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration splashDuration = Duration(seconds: 2);

  // ──────────────────────── Pagination ─────────────────────────────────
  static const int defaultPageSize = 20;
  static const int testHistoryPageSize = 10;
}
