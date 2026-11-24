import '../entities/review_queue.dart';
import '../repositories/review_repository.dart';

class GetTodayReview {
  const GetTodayReview(this._repository);

  final ReviewRepository _repository;

  Future<ReviewQueue> call() {
    return _repository.getTodayReview();
  }
}
