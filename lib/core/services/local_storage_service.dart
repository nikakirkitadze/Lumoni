import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:lumoni/core/constants/app_constants.dart';

/// Exception thrown by [LocalStorageService] operations.
class LocalStorageException implements Exception {
  final String message;
  final Object? originalError;

  const LocalStorageException(this.message, {this.originalError});

  @override
  String toString() => 'LocalStorageException: $message';
}

/// Hive-based local storage service for persisting user preferences,
/// cached scores, and recently used question IDs.
class LocalStorageService {
  Box? _preferencesBox;
  Box? _cacheBox;
  Box<List>? _questionHistoryBox;

  bool _initialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initializes Hive and opens all required boxes.
  ///
  /// Must be called once at app start before any read/write.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      _preferencesBox = await Hive.openBox(AppConstants.preferencesBox);
      _cacheBox = await Hive.openBox(AppConstants.cacheBox);
      _questionHistoryBox =
          await Hive.openBox<List>(AppConstants.questionHistoryBox);

      _initialized = true;
      debugPrint('[LocalStorageService] Hive initialized successfully.');
    } catch (e) {
      debugPrint('[LocalStorageService] Hive initialization failed: $e');
      throw LocalStorageException(
        'Failed to initialize local storage',
        originalError: e,
      );
    }
  }

  /// Ensures the service is initialized before any operation.
  void _assertInitialized() {
    if (!_initialized) {
      throw const LocalStorageException(
        'LocalStorageService has not been initialized. '
        'Call initialize() first.',
      );
    }
  }

  // ──────────────────────── Onboarding ─────────────────────────────────

  /// Returns whether onboarding has been completed.
  bool getOnboardingCompleted() {
    _assertInitialized();
    return _preferencesBox?.get(
          AppConstants.keyOnboardingCompleted,
          defaultValue: false,
        ) as bool? ??
        false;
  }

  /// Marks onboarding as completed.
  Future<void> setOnboardingCompleted(bool completed) async {
    _assertInitialized();
    await _preferencesBox?.put(
      AppConstants.keyOnboardingCompleted,
      completed,
    );
  }

  // ──────────────────────── Last Test Date ─────────────────────────────

  /// Returns the timestamp (ISO 8601 string) of the user's last test.
  DateTime? getLastTestDate() {
    _assertInitialized();
    final raw = _preferencesBox?.get(AppConstants.keyLastTestDate) as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Stores the last test date.
  Future<void> setLastTestDate(DateTime date) async {
    _assertInitialized();
    await _preferencesBox?.put(
      AppConstants.keyLastTestDate,
      date.toIso8601String(),
    );
  }

  /// Returns true if the test cooldown period has elapsed.
  bool canTakeTest() {
    final lastTest = getLastTestDate();
    if (lastTest == null) return true;
    return DateTime.now().difference(lastTest).inHours >=
        AppConstants.testCooldownHours;
  }

  // ──────────────────────── Cached Scores ──────────────────────────────

  /// Returns the locally cached IQ score, or null.
  int? getCachedIQScore() {
    _assertInitialized();
    return _cacheBox?.get(AppConstants.keyCachedIQScore) as int?;
  }

  /// Caches the latest IQ score.
  Future<void> setCachedIQScore(int score) async {
    _assertInitialized();
    await _cacheBox?.put(AppConstants.keyCachedIQScore, score);
  }

  /// Returns the locally cached EQ score, or null.
  double? getCachedEQScore() {
    _assertInitialized();
    return _cacheBox?.get(AppConstants.keyCachedEQScore) as double?;
  }

  /// Caches the latest EQ score.
  Future<void> setCachedEQScore(double score) async {
    _assertInitialized();
    await _cacheBox?.put(AppConstants.keyCachedEQScore, score);
  }

  // ──────────────────────── User Preferences ───────────────────────────

  /// Returns the stored theme mode string ('light', 'dark', or 'system').
  String getThemeMode() {
    _assertInitialized();
    return _preferencesBox?.get(
          AppConstants.keyThemeMode,
          defaultValue: 'system',
        ) as String? ??
        'system';
  }

  /// Stores the selected theme mode.
  Future<void> setThemeMode(String mode) async {
    _assertInitialized();
    await _preferencesBox?.put(AppConstants.keyThemeMode, mode);
  }

  /// Returns whether push notifications are enabled.
  bool getNotificationsEnabled() {
    _assertInitialized();
    return _preferencesBox?.get(
          AppConstants.keyNotificationsEnabled,
          defaultValue: true,
        ) as bool? ??
        true;
  }

  /// Stores the notification preference.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _assertInitialized();
    await _preferencesBox?.put(AppConstants.keyNotificationsEnabled, enabled);
  }

  // ──────────────────────── Free Test Counter ──────────────────────────

  /// Returns the number of free tests the user has consumed.
  int getFreeTestsUsed() {
    _assertInitialized();
    return _preferencesBox?.get(
          AppConstants.keyFreeTestsUsed,
          defaultValue: 0,
        ) as int? ??
        0;
  }

  /// Increments the free test counter by one.
  Future<void> incrementFreeTestsUsed() async {
    _assertInitialized();
    final current = getFreeTestsUsed();
    await _preferencesBox?.put(AppConstants.keyFreeTestsUsed, current + 1);
  }

  /// Returns whether the user has remaining free tests.
  bool hasRemainingFreeTests() {
    return getFreeTestsUsed() < AppConstants.freeTestLimit;
  }

  /// Returns how many free tests remain.
  int get remainingFreeTests =>
      (AppConstants.freeTestLimit - getFreeTestsUsed()).clamp(0, AppConstants.freeTestLimit);

  // ──────────────────────── User ID ────────────────────────────────────

  /// Returns the cached user ID (used for offline scenarios).
  String? getUserId() {
    _assertInitialized();
    return _preferencesBox?.get(AppConstants.keyUserId) as String?;
  }

  /// Caches the user ID locally.
  Future<void> setUserId(String? userId) async {
    _assertInitialized();
    if (userId == null) {
      await _preferencesBox?.delete(AppConstants.keyUserId);
    } else {
      await _preferencesBox?.put(AppConstants.keyUserId, userId);
    }
  }

  // ──────────────────────── Recently Used Question IDs ─────────────────

  /// Returns the list of recently used question IDs.
  List<String> getRecentQuestionIds() {
    _assertInitialized();
    final raw = _questionHistoryBox?.get(AppConstants.keyRecentQuestionIds);
    if (raw == null) return [];
    return raw.cast<String>();
  }

  /// Adds question IDs to the recently used list.
  ///
  /// Maintains a fixed-size window defined by
  /// [AppConstants.recentQuestionMemorySize]. Oldest entries are pruned first.
  Future<void> addRecentQuestionIds(List<String> ids) async {
    _assertInitialized();
    final current = getRecentQuestionIds();
    final updated = [...current, ...ids];

    // Keep only the most recent entries.
    final trimmed = updated.length > AppConstants.recentQuestionMemorySize
        ? updated.sublist(
            updated.length - AppConstants.recentQuestionMemorySize)
        : updated;

    await _questionHistoryBox?.put(
      AppConstants.keyRecentQuestionIds,
      trimmed,
    );
  }

  /// Clears all recently used question IDs.
  Future<void> clearRecentQuestionIds() async {
    _assertInitialized();
    await _questionHistoryBox?.delete(AppConstants.keyRecentQuestionIds);
  }

  // ──────────────────────── Generic Helpers ────────────────────────────

  /// Reads a value from the preferences box.
  T? getPreference<T>(String key, {T? defaultValue}) {
    _assertInitialized();
    return _preferencesBox?.get(key, defaultValue: defaultValue) as T?;
  }

  /// Writes a value to the preferences box.
  Future<void> setPreference<T>(String key, T value) async {
    _assertInitialized();
    await _preferencesBox?.put(key, value);
  }

  /// Reads a value from the cache box.
  T? getCacheValue<T>(String key) {
    _assertInitialized();
    return _cacheBox?.get(key) as T?;
  }

  /// Writes a value to the cache box.
  Future<void> setCacheValue<T>(String key, T value) async {
    _assertInitialized();
    await _cacheBox?.put(key, value);
  }

  // ──────────────────────── Cleanup ────────────────────────────────────

  /// Clears all cached data (not preferences).
  Future<void> clearCache() async {
    _assertInitialized();
    await _cacheBox?.clear();
  }

  /// Clears all stored data including preferences, cache, and history.
  /// Typically called on sign-out.
  Future<void> clearAll() async {
    _assertInitialized();
    await Future.wait([
      _preferencesBox?.clear() ?? Future.value(),
      _cacheBox?.clear() ?? Future.value(),
      _questionHistoryBox?.clear() ?? Future.value(),
    ]);
  }

  /// Closes all open Hive boxes.
  Future<void> dispose() async {
    await Hive.close();
    _initialized = false;
  }
}
