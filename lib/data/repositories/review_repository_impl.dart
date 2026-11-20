import '../../domain/entities/review_exercise.dart';
import '../../domain/entities/review_queue.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/review_history_item.dart';
import '../../domain/entities/review_history_query.dart';
import '../../domain/entities/review_submission.dart';
import '../../domain/entities/review_submission_result.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_data_source.dart';
import 'exception_mapper.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl(this._remoteDataSource);

  final ReviewRemoteDataSource _remoteDataSource;

  @override
  Future<ReviewQueue> getTodayReview() async {
    try {
      final model = await _remoteDataSource.getTodayReview();
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<ReviewExerciseSet> getExercises(String wordId) async {
    try {
      final model = await _remoteDataSource.getExercises(wordId);
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<PaginatedResult<ReviewHistoryItem>> getHistory(
    ReviewHistoryQuery query,
  ) async {
    try {
      final model = await _remoteDataSource.getHistory(query);
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<ReviewSubmissionResult> submitReview(
    ReviewSubmission submission,
  ) async {
    try {
      final model = await _remoteDataSource.submitReview(submission);
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }
}
