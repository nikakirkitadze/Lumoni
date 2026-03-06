import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:lumoni/firebase_options.dart';

/// Service responsible for initializing and configuring Firebase.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService _instance = FirebaseService._();

  /// Singleton accessor.
  static FirebaseService get instance => _instance;

  bool _initialized = false;

  /// Whether Firebase has been successfully initialized.
  bool get isInitialized => _initialized;

  /// Initializes Firebase with the default options for the current platform.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('[FirebaseService] Firebase initialized successfully.');
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseService] Firebase initialization failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseService] Unexpected error during Firebase init: $e');
      rethrow;
    }
  }

  /// Returns the current [FirebaseApp] instance.
  ///
  /// Throws [StateError] if Firebase has not been initialized.
  FirebaseApp get app {
    if (!_initialized) {
      throw StateError(
        'FirebaseService has not been initialized. '
        'Call FirebaseService.instance.initialize() first.',
      );
    }
    return Firebase.app();
  }
}
