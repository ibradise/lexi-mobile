import '../../core/error/app_failure.dart';
import '../entities/review_exercise.dart';
import '../repositories/review_repository.dart';

class GetReviewExercises {
  const GetReviewExercises(this._repository);

  final ReviewRepository _repository;

  Future<ReviewExerciseSet> call(String wordId) {
    final trimmed = wordId.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure(message: 'A word is required to review.');
    }
    return _repository.getExercises(trimmed);
  }
}
