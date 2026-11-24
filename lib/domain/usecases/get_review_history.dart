import '../entities/paginated_result.dart';
import '../entities/review_history_item.dart';
import '../entities/review_history_query.dart';
import '../repositories/review_repository.dart';

class GetReviewHistory {
  const GetReviewHistory(this._repository);

  final ReviewRepository _repository;

  Future<PaginatedResult<ReviewHistoryItem>> call(ReviewHistoryQuery query) {
    final wordId = query.wordId?.trim();

    return _repository.getHistory(
      query.copyWith(
        wordId: wordId == null || wordId.isEmpty ? null : wordId,
        clearWordId: wordId == null || wordId.isEmpty,
        page: query.page < 1 ? 1 : query.page,
        limit: query.limit.clamp(1, 100).toInt(),
      ),
    );
  }
}
