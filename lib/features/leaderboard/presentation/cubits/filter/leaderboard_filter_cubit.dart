import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';

class LeaderboardFilterCubit extends Cubit<LeaderboardFilter> {
  LeaderboardFilterCubit({
    required LocalStorageService localStorage,
    LeaderboardFilter? initialFilter,
  }) : _localStorage = localStorage,
       super(initialFilter ?? const LeaderboardFilter());

  final LocalStorageService _localStorage;

  static const String _cacheKey = 'leaderboard_filter_state';

  Future<void> loadCachedFilter() async {
    final raw = _localStorage.getCacheValue<String>(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      emit(LeaderboardFilter.fromJson(decoded));
    } catch (_) {
      // Ignore malformed cache and keep defaults.
    }
  }

  Future<void> setMetric(LeaderboardMetric metric) async {
    final updated = state.copyWith(metric: metric);
    emit(updated);
    await _persist(updated);
  }

  Future<void> setScope(LeaderboardScopeType scopeType) async {
    var updated = state.copyWith(scopeType: scopeType);
    if (scopeType == LeaderboardScopeType.global) {
      updated = updated.copyWith(clearCountryCode: true);
    }
    emit(updated);
    await _persist(updated);
  }

  Future<void> setPeriod(LeaderboardPeriod period) async {
    final updated = state.copyWith(period: period);
    emit(updated);
    await _persist(updated);
  }

  Future<void> setCountry(String countryCode) async {
    final normalized = countryCode.trim().toUpperCase();
    final updated = state.copyWith(
      scopeType: LeaderboardScopeType.country,
      countryCode: normalized,
    );
    emit(updated);
    await _persist(updated);
  }

  Future<void> _persist(LeaderboardFilter filter) async {
    await _localStorage.setCacheValue<String>(
      _cacheKey,
      jsonEncode(filter.toJson()),
    );
  }
}
