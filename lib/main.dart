import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lumoni/app/app.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/firebase_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/core/services/auth_service.dart';

/// Lumoni - Premium Intelligence Platform
///
/// Main entry point. Initializes Firebase, Hive, dependency injection,
/// and configures system UI before launching the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure dark system UI overlay for the dark theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0F172A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase (gracefully handles missing config for development).
  try {
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint(
      '[main] Firebase initialization failed. '
      'Running in offline mode: $e',
    );
  }

  // Register all services in the service locator.
  await configureDependencies();

  // Initialize Hive-based local storage independently of Firebase.
  try {
    await getIt<LocalStorageService>().initialize();
  } catch (e) {
    debugPrint('[main] Local storage initialization failed: $e');
  }

  // Initialize RevenueCat subscription service (non-blocking).
  try {
    String? userId;
    if (FirebaseService.instance.isInitialized) {
      userId = getIt<AuthService>().currentUser?.uid;
    }
    await getIt<SubscriptionService>().initialize(userId: userId);
  } catch (e) {
    debugPrint('[main] Subscription service initialization failed: $e');
  }

  runApp(const LumoniApp());
}
