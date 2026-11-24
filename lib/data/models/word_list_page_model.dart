import '../../domain/entities/paginated_result.dart';
import 'word_summary_model.dart';

class WordListPageModel {
  const WordListPageModel({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<WordSummaryModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResult<T> toEntity<T>(T Function(WordSummaryModel) mapper) {
    return PaginatedResult(
      items: [for (final item in items) mapper(item)],
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }
}
