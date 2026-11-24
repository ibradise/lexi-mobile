import 'learning_state.dart';
import 'review_entry.dart';
import 'score_breakdown.dart';

class ReviewSubmissionResult {
  const ReviewSubmissionResult({
    required this.review,
    required this.learningState,
    required this.scoreBreakdown,
  });

  final ReviewEntry review;
  final LearningState learningState;
  final ScoreBreakdown scoreBreakdown;
}
