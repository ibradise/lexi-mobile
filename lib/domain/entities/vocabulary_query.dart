import 'learning_state.dart';

enum VocabularySort {
  dateAdded('dateAdded'),
  word('word');

  const VocabularySort(this.wireValue);

  final String wireValue;
}

enum VocabularyOrder {
  ascending('asc'),
  descending('desc');

  const VocabularyOrder(this.wireValue);

  final String wireValue;
}

class VocabularyQuery {
  const VocabularyQuery({
    this.search,
    this.status,
    this.sort = VocabularySort.dateAdded,
    this.order = VocabularyOrder.descending,
    this.page = 1,
    this.limit = 20,
  });

  final String? search;
  final LearningStatus? status;
  final VocabularySort sort;
  final VocabularyOrder order;
  final int page;
  final int limit;

  bool get hasFilters => search != null || status != null;

  VocabularyQuery copyWith({
    String? search,
    bool clearSearch = false,
    LearningStatus? status,
    bool clearStatus = false,
    VocabularySort? sort,
    VocabularyOrder? order,
    int? page,
    int? limit,
  }) {
    return VocabularyQuery(
      search: clearSearch ? null : search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}
