import '../../domain/entities/learning_state.dart';
import 'model_utils.dart';

class LearningStateModel {
  const LearningStateModel({
    required this.status,
    required this.knowledgeScore,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  factory LearningStateModel.fromJson(Map<String, dynamic> json) {
    return LearningStateModel(
      status: _parseStatus(json['status']),
      knowledgeScore: optionalDouble(json['knowledgeScore']),
      easeFactor: optionalDouble(json['easeFactor'], fallback: 2.5),
      intervalDays: optionalInt(json['intervalDays']),
      repetitions: optionalInt(json['repetitions']),
      nextReviewAt: optionalDate(json['nextReviewAt']),
      lastReviewedAt: optionalDate(json['lastReviewedAt']),
    );
  }

  final LearningStatus status;
  final double knowledgeScore;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  LearningState toEntity() {
    return LearningState(
      status: status,
      knowledgeScore: knowledgeScore,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitions: repetitions,
      nextReviewAt: nextReviewAt,
      lastReviewedAt: lastReviewedAt,
    );
  }

  static LearningStatus _parseStatus(Object? value) {
    return switch (value) {
      'LEARNING' => LearningStatus.learning,
      'FAMILIAR' => LearningStatus.familiar,
      'STRONG' => LearningStatus.strong,
      'MASTERED' => LearningStatus.mastered,
      _ => LearningStatus.newWord,
    };
  }
}
