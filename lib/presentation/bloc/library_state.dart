import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/vocabulary_query.dart';
import '../../domain/entities/word_summary.dart';

class LibraryState extends Equatable {
  const LibraryState({
    this.query = const VocabularyQuery(),
    this.items = const [],
    this.total = 0,
    this.totalPages = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final VocabularyQuery query;
  final List<WordSummary> items;
  final int total;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final AppFailure? failure;
  final AppFailure? loadMoreFailure;

  bool get hasMore => query.page < totalPages;

  bool get isEmpty => !isLoading && failure == null && items.isEmpty;

  bool get hasFilters => query.hasFilters;

  LibraryState copyWith({
    VocabularyQuery? query,
    List<WordSummary>? items,
    int? total,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) {
    return LibraryState(
      query: query ?? this.query,
      items: items ?? this.items,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : failure ?? this.failure,
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : loadMoreFailure ?? this.loadMoreFailure,
    );
  }

  @override
  List<Object?> get props => [
    query.search,
    query.status,
    query.sort,
    query.order,
    query.page,
    query.limit,
    [
      for (final item in items)
        '${item.id}:${item.word}:${item.aiReady}:'
            '${item.learningState?.status.wireValue}',
    ],
    total,
    totalPages,
    isLoading,
    isLoadingMore,
    failure,
    loadMoreFailure,
  ];
}
