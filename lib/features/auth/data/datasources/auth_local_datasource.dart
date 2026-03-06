import 'package:hive/hive.dart';
import 'package:lumoni/core/constants/app_constants.dart';

/// Local data source that caches authentication state using Hive.
///
/// Stores the last known UID, email, and provider so the app can quickly
/// determine whether to show the logged-in experience while Firebase
/// re-validates the token on cold start.
class AuthLocalDatasource {
  AuthLocalDatasource({Box? preferencesBox})
      : _box = preferencesBox ?? Hive.box(AppConstants.preferencesBox);

  final Box _box;

  // ─────────────── Hive Keys ──────────────────────────────────────────────

  static const _keyUid = 'auth_cached_uid';
  static const _keyEmail = 'auth_cached_email';
  static const _keyProvider = 'auth_cached_provider';
  static const _keyLastLogin = 'auth_cached_last_login';

  // ─────────────── Read ───────────────────────────────────────────────────

  /// The cached UID from the last successful sign-in, or `null` if absent.
  String? get cachedUid => _box.get(_keyUid) as String?;

  /// The cached email, or `null`.
  String? get cachedEmail => _box.get(_keyEmail) as String?;

  /// The cached authentication provider (google, apple, email).
  String? get cachedProvider => _box.get(_keyProvider) as String?;

  /// The ISO-8601 timestamp of the last login, or `null`.
  String? get lastLoginTimestamp => _box.get(_keyLastLogin) as String?;

  /// Whether we have any cached auth session.
  bool get hasCachedSession => cachedUid != null;

  // ─────────────── Write ──────────────────────────────────────────────────

  /// Persists authentication details to local storage after a successful
  /// sign-in.
  Future<void> cacheAuthState({
    required String uid,
    String? email,
    String? provider,
  }) async {
    await _box.put(_keyUid, uid);
    if (email != null) await _box.put(_keyEmail, email);
    if (provider != null) await _box.put(_keyProvider, provider);
    await _box.put(_keyLastLogin, DateTime.now().toIso8601String());
  }

  /// Removes all cached auth data (used on sign-out).
  Future<void> clearAuthState() async {
    await _box.delete(_keyUid);
    await _box.delete(_keyEmail);
    await _box.delete(_keyProvider);
    await _box.delete(_keyLastLogin);
  }

  // ─────────────── Onboarding ─────────────────────────────────────────────

  /// Whether onboarding has been completed.
  bool get isOnboardingCompleted =>
      _box.get(AppConstants.keyOnboardingCompleted, defaultValue: false)
          as bool;

  /// Marks onboarding as completed.
  Future<void> setOnboardingCompleted() async {
    await _box.put(AppConstants.keyOnboardingCompleted, true);
  }
}
