import '../../domain/entities/review_entry.dart';
import 'model_utils.dart';

class ReviewEntryModel {
  const ReviewEntryModel({
    required this.id,
    required this.exerciseType,
    required this.result,
    this.responseTimeMs,
    this.hintUsed = false,
    this.userAnswer,
    this.correctAnswer,
    this.createdAt,
  });

  factory ReviewEntryModel.fromJson(Map<String, dynamic> json) {
    return ReviewEntryModel(
      id: requireString(json, 'id'),
      exerciseType: requireString(json, 'exerciseType'),
      result: _parseResult(json['result']),
      responseTimeMs: json['responseTimeMs'] is num
          ? (json['responseTimeMs'] as num).toInt()
          : null,
      hintUsed: json['hintUsed'] == true,
      userAnswer: optionalString(json['userAnswer']),
      correctAnswer: optionalString(json['correctAnswer']),
      createdAt: optionalDate(json['createdAt']),
    );
  }

  final String id;
  final String exerciseType;
  final ReviewResult result;
  final int? responseTimeMs;
  final bool hintUsed;
  final String? userAnswer;
  final String? correctAnswer;
  final DateTime? createdAt;

  ReviewEntry toEntity() {
    return ReviewEntry(
      id: id,
      exerciseType: exerciseType,
      result: result,
      responseTimeMs: responseTimeMs,
      hintUsed: hintUsed,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      createdAt: createdAt,
    );
  }

  static ReviewResult _parseResult(Object? value) {
    return switch (value) {
      'CORRECT' => ReviewResult.correct,
      'INCORRECT' => ReviewResult.incorrect,
      'PARTIAL' => ReviewResult.partial,
      _ => ReviewResult.skipped,
    };
  }
}
