import '../entities/paginated_result.dart';
import '../entities/vocabulary_query.dart';
import '../entities/word_summary.dart';
import '../repositories/vocabulary_repository.dart';

class GetWords {
  const GetWords(this._repository);

  final VocabularyRepository _repository;

  Future<PaginatedResult<WordSummary>> call(VocabularyQuery query) {
    final search = query.search?.trim();

    return _repository.getWords(
      query.copyWith(
        search: search == null || search.isEmpty ? null : search,
        clearSearch: search == null || search.isEmpty,
        page: query.page < 1 ? 1 : query.page,
        limit: query.limit.clamp(1, 100).toInt(),
      ),
    );
  }
}
