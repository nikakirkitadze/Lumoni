import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/features/results/presentation/cubits/results_state.dart';
import 'package:lumoni/features/share_card/data/models/share_card_config.dart';
import 'package:lumoni/features/share_card/presentation/cubits/share_card_state.dart';

/// Manages the share-card builder lifecycle: loading data, customization,
/// image capture, and sharing.
class ShareCardCubit extends Cubit<ShareCardState> {
  ShareCardCubit({
    SubscriptionService? subscriptionService,
  })  : _subscriptionService =
            subscriptionService ?? getIt<SubscriptionService>(),
        super(const ShareCardInitial());

  final SubscriptionService _subscriptionService;

  /// Global key attached to the RepaintBoundary wrapping the card preview.
  final GlobalKey repaintBoundaryKey = GlobalKey();

  // ──────────────────────── Load ─────────────────────────────────────────

  /// Loads results for the given [sessionId] and prepares the card builder.
  Future<void> loadSession(String sessionId,
      {TestSessionModel? session}) async {
    emit(const ShareCardLoading());

    try {
      TestSessionModel? loaded;
      try {
        loaded =
            await getIt<FirestoreService>().getTestSession(sessionId);
      } catch (e) {
        debugPrint('[ShareCardCubit] Firestore fetch failed: $e');
      }

      final resolvedSession = loaded ?? session;
      if (resolvedSession == null) {
        emit(const ShareCardError(message: 'Could not load test results.'));
        return;
      }

      final isIQ = resolvedSession.testType == TestType.iq;
      final categoryScores =
          Map<String, double>.from(resolvedSession.categoryScores);

      late ResultsLoaded results;
      if (isIQ) {
        final iqScore =
            (resolvedSession.score ?? AppConstants.iqMean).round();
        final percentile = _calculatePercentile(iqScore.toDouble());
        final classification = AppConstants.iqClassification(iqScore);
        results = ResultsLoaded(
          session: resolvedSession,
          isIQ: true,
          iqScore: iqScore,
          iqPercentile: percentile,
          iqClassification: classification,
          categoryScores: categoryScores,
        );
      } else {
        final eqScore =
            resolvedSession.score ?? _calculateOverallEQ(categoryScores);
        final classification = AppConstants.eqClassification(eqScore);
        results = ResultsLoaded(
          session: resolvedSession,
          isIQ: false,
          eqScore: eqScore,
          eqClassification: classification,
          categoryScores: categoryScores,
        );
      }

      final cardType =
          isIQ ? ShareCardType.iqScore : ShareCardType.eqScore;

      emit(ShareCardReady(
        results: results,
        config: ShareCardConfig(cardType: cardType),
      ));
    } catch (e) {
      emit(ShareCardError(message: 'Failed to load results: $e'));
    }
  }

  /// Initializes the builder directly from an existing [ResultsLoaded].
  void loadFromResults(ResultsLoaded results) {
    final cardType =
        results.isIQ ? ShareCardType.iqScore : ShareCardType.eqScore;
    emit(ShareCardReady(
      results: results,
      config: ShareCardConfig(cardType: cardType),
    ));
  }

  // ──────────────────────── Customization ────────────────────────────────

  /// Changes the card style. Rejects premium styles for free users.
  void setStyle(ShareCardStyle style) {
    final current = state;
    if (current is! ShareCardReady) return;

    if (style.isPremium && !_subscriptionService.isPremium) {
      return; // UI should show paywall prompt
    }

    emit(current.copyWith(config: current.config.copyWith(style: style)));
  }

  /// Changes the aspect ratio.
  void setAspectRatio(ShareCardAspectRatio ratio) {
    final current = state;
    if (current is! ShareCardReady) return;
    emit(current.copyWith(config: current.config.copyWith(aspectRatio: ratio)));
  }

  /// Changes the card type.
  void setCardType(ShareCardType type) {
    final current = state;
    if (current is! ShareCardReady) return;
    emit(current.copyWith(config: current.config.copyWith(cardType: type)));
  }

  /// Toggles category breakdown visibility.
  void toggleCategoryBreakdown() {
    final current = state;
    if (current is! ShareCardReady) return;
    emit(current.copyWith(
      config: current.config.copyWith(
        showCategoryBreakdown: !current.config.showCategoryBreakdown,
      ),
    ));
  }

  /// Toggles percentile label visibility.
  void togglePercentile() {
    final current = state;
    if (current is! ShareCardReady) return;
    emit(current.copyWith(
      config: current.config.copyWith(
        showPercentile: !current.config.showPercentile,
      ),
    ));
  }

  /// Returns true if the given style is accessible to the current user.
  bool isStyleAccessible(ShareCardStyle style) {
    return style.isFree || _subscriptionService.isPremium;
  }

  // ──────────────────────── Export & Share ────────────────────────────────

  /// Captures the card widget as a PNG image.
  Future<Uint8List?> captureCard() async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(
        pixelRatio: AppConstants.shareCardPixelRatio,
      );
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ShareCardCubit] Capture error: $e');
      return null;
    }
  }

  /// Captures the card and shares via the system share sheet.
  Future<void> shareCard() async {
    final current = state;
    ResultsLoaded? results;
    ShareCardConfig? config;

    if (current is ShareCardReady) {
      results = current.results;
      config = current.config;
    } else if (current is ShareCardExported) {
      results = current.results;
      config = current.config;
    }

    if (results == null || config == null) return;

    emit(ShareCardExporting(results: results, config: config));

    final bytes = await captureCard();
    if (bytes == null) {
      emit(ShareCardError(
        message: 'Failed to capture card image.',
        results: results,
        config: config,
      ));
      // Restore ready state
      emit(ShareCardReady(results: results, config: config));
      return;
    }

    try {
      final shareText = _buildShareText(results, config);
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'lumoni_card.png')],
        text: shareText,
      );

      emit(ShareCardExported(
        results: results,
        config: config,
        imageBytes: bytes,
      ));
      // Return to ready state for further sharing
      emit(ShareCardReady(results: results, config: config));
    } catch (e) {
      debugPrint('[ShareCardCubit] Share error: $e');
      emit(ShareCardReady(results: results, config: config));
    }
  }

  /// Captures the card and saves to gallery.
  Future<Uint8List?> saveToGallery() async {
    final current = state;
    ResultsLoaded? results;
    ShareCardConfig? config;

    if (current is ShareCardReady) {
      results = current.results;
      config = current.config;
    }

    if (results == null || config == null) return null;

    emit(ShareCardExporting(results: results, config: config));

    final bytes = await captureCard();
    if (bytes == null) {
      emit(ShareCardReady(results: results, config: config));
      return null;
    }

    emit(ShareCardExported(
      results: results,
      config: config,
      imageBytes: bytes,
    ));
    emit(ShareCardReady(results: results, config: config));
    return bytes;
  }

  // ──────────────────────── Helpers ──────────────────────────────────────

  String _buildShareText(ResultsLoaded results, ShareCardConfig config) {
    if (results.isIQ) {
      final percentileText =
          'Top ${(100 - results.iqPercentile).toStringAsFixed(0)}%';
      return 'My IQ Score: ${results.iqScore} '
          '($percentileText) - ${results.iqClassification}\n'
          'Tested with Lumoni';
    } else {
      return 'My EQ Score: ${results.eqScore.toStringAsFixed(0)}/100 '
          '- ${results.eqClassification}\n'
          'Tested with Lumoni';
    }
  }

  double _calculatePercentile(double iqScore) {
    final z =
        (iqScore - AppConstants.iqMean) / AppConstants.iqStandardDeviation;
    return _normalCDF(z) * 100;
  }

  double _normalCDF(double z) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final sign = z < 0 ? -1 : 1;
    final x = z.abs() / math.sqrt(2);
    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            math.exp(-x * x);
    return 0.5 * (1.0 + sign * y);
  }

  double _calculateOverallEQ(Map<String, double> categoryScores) {
    if (categoryScores.isEmpty) return 0;
    final total = categoryScores.values.fold<double>(0, (sum, v) => sum + v);
    return total / categoryScores.length;
  }
}
