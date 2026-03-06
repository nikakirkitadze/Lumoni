import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:lumoni/core/services/ai_question_service.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/firebase_service.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/core/utils/eq_score_calculator.dart';
import 'package:lumoni/core/utils/iq_score_calculator.dart';
import 'package:lumoni/core/utils/question_randomizer.dart';
import 'package:lumoni/features/iq_test/data/repositories/iq_test_repository.dart';
import 'package:lumoni/features/eq_test/data/repositories/eq_test_repository.dart';
import 'package:lumoni/features/leaderboard/data/repositories/firestore_leaderboard_repository.dart';
import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Global service locator.
final GetIt getIt = GetIt.instance;

/// Registers all services, repositories, and cubits in the service locator.
///
/// Call this once before [runApp] after platform channel initialization.
Future<void> configureDependencies() async {
  // ─────────────────────── Core Services (singletons) ──────────────────

  // Firebase must be initialized before anything that depends on it.
  getIt.registerSingleton<FirebaseService>(FirebaseService.instance);

  // Local storage (Hive) -- must be initialized before use.
  getIt.registerSingleton<LocalStorageService>(LocalStorageService());

  // Auth wraps FirebaseAuth.
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Firestore wraps Cloud Firestore.
  getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // RevenueCat subscription management.
  getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());

  // ─────────────────────── AI Services ───────────────────────────────

  getIt.registerLazySingleton<AIQuestionService>(
    () => AIQuestionService(localStorage: getIt<LocalStorageService>()),
  );

  // ─────────────────────── Repositories ──────────────────────────────

  getIt.registerLazySingleton<IQTestRepository>(
    () => IQTestRepository(aiService: getIt<AIQuestionService>()),
  );
  getIt.registerLazySingleton<EQTestRepository>(() => EQTestRepository());
  getIt.registerLazySingleton<LeaderboardRepository>(
    () => FirestoreLeaderboardRepository(
      firestore: FirebaseFirestore.instance,
      functions: FirebaseFunctions.instance,
      authService: getIt<AuthService>(),
      localStorage: getIt<LocalStorageService>(),
    ),
  );

  // ─────────────────────── Utilities (singletons) ──────────────────────

  getIt.registerLazySingleton<IQScoreCalculator>(() => IQScoreCalculator());
  getIt.registerLazySingleton<EQScoreCalculator>(() => EQScoreCalculator());
  getIt.registerLazySingleton<QuestionRandomizer>(
    () => QuestionRandomizer(localStorage: getIt<LocalStorageService>()),
  );
}

/// Initializes async singletons that require awaiting.
///
/// Call after [configureDependencies].
Future<void> initializeAsyncDependencies() async {
  // Initialize Firebase first.
  await getIt<FirebaseService>().initialize();

  // Initialize Hive-based local storage.
  await getIt<LocalStorageService>().initialize();

  // Initialize RevenueCat (non-blocking -- failures are logged, not thrown).
  try {
    String? userId;
    if (getIt<FirebaseService>().isInitialized) {
      userId = getIt<AuthService>().currentUser?.uid;
    }
    await getIt<SubscriptionService>().initialize(userId: userId);
  } catch (e) {
    // Subscription init failure should not block app start.
    // ignore: avoid_print
    print('[DI] SubscriptionService init warning: $e');
  }
}
