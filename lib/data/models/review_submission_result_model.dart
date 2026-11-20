import '../../domain/entities/review_submission_result.dart';
import '../../domain/entities/score_breakdown.dart';
import 'learning_state_model.dart';
import 'model_utils.dart';
import 'review_entry_model.dart';

class ScoreBreakdownModel {
  const ScoreBreakdownModel({
    required this.accuracy,
    required this.interval,
    required this.responseTime,
    required this.hint,
    required this.repetition,
  });

  factory ScoreBreakdownModel.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdownModel(
      accuracy: optionalDouble(json['accuracy']),
      interval: optionalDouble(json['interval']),
      responseTime: optionalDouble(json['responseTime']),
      hint: optionalDouble(json['hint']),
      repetition: optionalDouble(json['repetition']),
    );
  }

  final double accuracy;
  final double interval;
  final double responseTime;
  final double hint;
  final double repetition;

  ScoreBreakdown toEntity() {
    return ScoreBreakdown(
      accuracy: accuracy,
      interval: interval,
      responseTime: responseTime,
      hint: hint,
      repetition: repetition,
    );
  }
}

class ReviewSubmissionResultModel {
  const ReviewSubmissionResultModel({
    required this.review,
    required this.learningState,
    required this.scoreBreakdown,
  });

  factory ReviewSubmissionResultModel.fromJson(Map<String, dynamic> json) {
    final reviewValue = json['review'];
    final learningStateValue = json['learningState'];
    final scoreBreakdownValue = json['scoreBreakdown'];

    if (reviewValue is! Map<String, dynamic> ||
        learningStateValue is! Map<String, dynamic> ||
        scoreBreakdownValue is! Map<String, dynamic>) {
      throw const FormatException('Incomplete review submission response.');
    }

    return ReviewSubmissionResultModel(
      review: ReviewEntryModel.fromJson(reviewValue),
      learningState: LearningStateModel.fromJson(learningStateValue),
      scoreBreakdown: ScoreBreakdownModel.fromJson(scoreBreakdownValue),
    );
  }

  final ReviewEntryModel review;
  final LearningStateModel learningState;
  final ScoreBreakdownModel scoreBreakdown;

  ReviewSubmissionResult toEntity() {
    return ReviewSubmissionResult(
      review: review.toEntity(),
      learningState: learningState.toEntity(),
      scoreBreakdown: scoreBreakdown.toEntity(),
    );
  }
}
