import '../../core/error/app_failure.dart';
import '../entities/review_submission.dart';
import '../entities/review_submission_result.dart';
import '../repositories/review_repository.dart';

class SubmitReview {
  const SubmitReview(this._repository);

  final ReviewRepository _repository;

  Future<ReviewSubmissionResult> call(ReviewSubmission submission) {
    final wordId = submission.wordId.trim();
    final exerciseId = submission.exerciseId.trim();
    final submissionId = submission.submissionId?.trim();

    if (wordId.isEmpty) {
      throw const ValidationFailure(message: 'A word is required to review.');
    }
    if (exerciseId.isEmpty) {
      throw const ValidationFailure(
        message: 'An exercise is required to submit a review.',
      );
    }
    if (!submission.skipped &&
        (submission.userAnswer == null || submission.userAnswer!.isEmpty)) {
      throw const ValidationFailure(message: 'Choose an answer first.');
    }

    return _repository.submitReview(
      ReviewSubmission(
        wordId: wordId,
        exerciseId: exerciseId,
        userAnswer: submission.userAnswer,
        responseTimeMs: submission.responseTimeMs?.clamp(0, 60000),
        hintUsed: submission.hintUsed,
        skipped: submission.skipped,
        submissionId: submissionId == null || submissionId.isEmpty
            ? null
            : submissionId,
      ),
    );
  }
}
