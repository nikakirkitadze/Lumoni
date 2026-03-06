import 'package:equatable/equatable.dart';

class LeaderboardTier extends Equatable {
  const LeaderboardTier({
    required this.id,
    required this.label,
    required this.minPercentile,
    required this.maxPercentile,
    required this.colorHex,
    required this.benefitText,
  });

  final String id;
  final String label;
  final double minPercentile;
  final double maxPercentile;
  final String colorHex;
  final String benefitText;

  bool containsPercentile(double percentile) {
    return percentile >= minPercentile && percentile <= maxPercentile;
  }

  @override
  List<Object?> get props => [
    id,
    label,
    minPercentile,
    maxPercentile,
    colorHex,
    benefitText,
  ];
}
