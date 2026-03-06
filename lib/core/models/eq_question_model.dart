import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a single EQ (Emotional Quotient) assessment statement.
///
/// Users respond on a Likert scale (1 = Strongly Disagree, 5 = Strongly Agree).
/// Some statements are reverse-scored, meaning a high Likert response maps to a
/// low score for that category.
class EQQuestionModel extends Equatable {
  /// Unique question identifier.
  final String id;

  /// The statement the user rates on a Likert scale.
  final String statement;

  /// EQ category: selfAwareness, selfRegulation, motivation, empathy,
  /// or socialSkills.
  final String category;

  /// Whether this item is reverse-scored.
  ///
  /// If true, the Likert response is inverted before computing the score:
  /// scored_value = (likertMax + likertMin) - raw_value.
  final bool isReversed;

  /// Weight multiplier for this question's contribution to the category score.
  /// Typical value is 1.0. Higher weights emphasize more discriminating items.
  final double weight;

  const EQQuestionModel({
    required this.id,
    required this.statement,
    required this.category,
    this.isReversed = false,
    this.weight = 1.0,
  });

  @override
  List<Object?> get props => [id, statement, category, isReversed, weight];

  /// Computes the effective score for a raw Likert [response] (1-5).
  ///
  /// If [isReversed] is true, the response is inverted first.
  /// Returns a value in the range [1, 5].
  double effectiveScore(int response, {int likertMin = 1, int likertMax = 5}) {
    assert(response >= likertMin && response <= likertMax);
    final adjusted =
        isReversed ? (likertMax + likertMin) - response : response;
    return adjusted * weight;
  }

  factory EQQuestionModel.fromJson(Map<String, dynamic> json) {
    return EQQuestionModel(
      id: json['id'] as String,
      statement: json['statement'] as String,
      category: json['category'] as String,
      isReversed: json['isReversed'] as bool? ?? false,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  factory EQQuestionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return EQQuestionModel(
      id: doc.id,
      statement: data['statement'] as String,
      category: data['category'] as String,
      isReversed: data['isReversed'] as bool? ?? false,
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'statement': statement,
      'category': category,
      'isReversed': isReversed,
      'weight': weight,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'statement': statement,
      'category': category,
      'isReversed': isReversed,
      'weight': weight,
    };
  }

  EQQuestionModel copyWith({
    String? id,
    String? statement,
    String? category,
    bool? isReversed,
    double? weight,
  }) {
    return EQQuestionModel(
      id: id ?? this.id,
      statement: statement ?? this.statement,
      category: category ?? this.category,
      isReversed: isReversed ?? this.isReversed,
      weight: weight ?? this.weight,
    );
  }
}
