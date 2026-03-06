import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:lumoni/features/results/presentation/cubits/results_state.dart';
import 'package:lumoni/features/share_card/data/models/share_card_config.dart';

/// Base state for the share-card builder.
sealed class ShareCardState extends Equatable {
  const ShareCardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before results are loaded.
class ShareCardInitial extends ShareCardState {
  const ShareCardInitial();
}

/// Loading results data for the card.
class ShareCardLoading extends ShareCardState {
  const ShareCardLoading();
}

/// Card is ready for preview and customization.
class ShareCardReady extends ShareCardState {
  /// The resolved test results used to populate the card.
  final ResultsLoaded results;

  /// Current card configuration (style, aspect ratio, toggles).
  final ShareCardConfig config;

  const ShareCardReady({
    required this.results,
    required this.config,
  });

  ShareCardReady copyWith({
    ResultsLoaded? results,
    ShareCardConfig? config,
  }) {
    return ShareCardReady(
      results: results ?? this.results,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [results, config];
}

/// The card image is being captured / exported.
class ShareCardExporting extends ShareCardState {
  final ResultsLoaded results;
  final ShareCardConfig config;

  const ShareCardExporting({
    required this.results,
    required this.config,
  });

  @override
  List<Object?> get props => [results, config];
}

/// Card has been exported to bytes, ready to share or save.
class ShareCardExported extends ShareCardState {
  final ResultsLoaded results;
  final ShareCardConfig config;
  final Uint8List imageBytes;

  const ShareCardExported({
    required this.results,
    required this.config,
    required this.imageBytes,
  });

  @override
  List<Object?> get props => [results, config, imageBytes];
}

/// An error occurred during export or sharing.
class ShareCardError extends ShareCardState {
  final String message;
  final ResultsLoaded? results;
  final ShareCardConfig? config;

  const ShareCardError({
    required this.message,
    this.results,
    this.config,
  });

  @override
  List<Object?> get props => [message, results, config];
}
