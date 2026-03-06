import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// The type of intelligence test.
enum TestType {
  iq('iq'),
  eq('eq');

  final String value;
  const TestType(this.value);

  static TestType fromString(String value) {
    return TestType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TestType.iq,
    );
  }
}

/// Represents a single completed (or in-progress) test session.
class TestSessionModel extends Equatable {
  final String id;
  final String userId;
  final TestType testType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? score;
  final Map<String, double> categoryScores;
  final List<String> questionIds;
  final Map<String, int> answers;
  final int timeSpentSeconds;

  const TestSessionModel({
    required this.id,
    required this.userId,
    required this.testType,
    required this.startedAt,
    this.completedAt,
    this.score,
    this.categoryScores = const {},
    this.questionIds = const [],
    this.answers = const {},
    this.timeSpentSeconds = 0,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        testType,
        startedAt,
        completedAt,
        score,
        categoryScores,
        questionIds,
        answers,
        timeSpentSeconds,
      ];

  /// Whether the test session has been completed.
  bool get isCompleted => completedAt != null;

  /// Duration of the test session.
  Duration get duration => Duration(seconds: timeSpentSeconds);

  /// Number of questions answered.
  int get answeredCount => answers.length;

  /// Number of total questions in the session.
  int get totalQuestions => questionIds.length;

  /// Progress as a fraction (0.0 to 1.0).
  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  factory TestSessionModel.fromJson(Map<String, dynamic> json) {
    return TestSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      testType: TestType.fromString(json['testType'] as String),
      startedAt: json['startedAt'] is String
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
      completedAt: json['completedAt'] != null
          ? json['completedAt'] is String
              ? DateTime.parse(json['completedAt'] as String)
              : DateTime.fromMillisecondsSinceEpoch(
                  json['completedAt'] as int)
          : null,
      score: (json['score'] as num?)?.toDouble(),
      categoryScores: (json['categoryScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      questionIds: (json['questionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      answers: (json['answers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
    );
  }

  factory TestSessionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TestSessionModel(
      id: doc.id,
      userId: data['userId'] as String,
      testType: TestType.fromString(data['testType'] as String),
      startedAt:
          (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      score: (data['score'] as num?)?.toDouble(),
      categoryScores: (data['categoryScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      questionIds: (data['questionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      answers: (data['answers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
      timeSpentSeconds: data['timeSpentSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'testType': testType.value,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'score': score,
      'categoryScores': categoryScores,
      'questionIds': questionIds,
      'answers': answers,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'testType': testType.value,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'score': score,
      'categoryScores': categoryScores,
      'questionIds': questionIds,
      'answers': answers,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  TestSessionModel copyWith({
    String? id,
    String? userId,
    TestType? testType,
    DateTime? startedAt,
    DateTime? completedAt,
    double? score,
    Map<String, double>? categoryScores,
    List<String>? questionIds,
    Map<String, int>? answers,
    int? timeSpentSeconds,
  }) {
    return TestSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testType: testType ?? this.testType,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      categoryScores: categoryScores ?? this.categoryScores,
      questionIds: questionIds ?? this.questionIds,
      answers: answers ?? this.answers,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }
}
