import '../entities/paginated_result.dart';
import '../entities/review_exercise.dart';
import '../entities/review_history_item.dart';
import '../entities/review_history_query.dart';
import '../entities/review_queue.dart';
import '../entities/review_submission.dart';
import '../entities/review_submission_result.dart';

abstract interface class ReviewRepository {
  Future<ReviewQueue> getTodayReview();

  Future<ReviewExerciseSet> getExercises(String wordId);

  Future<ReviewSubmissionResult> submitReview(ReviewSubmission submission);

  Future<PaginatedResult<ReviewHistoryItem>> getHistory(
    ReviewHistoryQuery query,
  );
}
