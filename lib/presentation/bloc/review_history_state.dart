import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_history_item.dart';
import '../../domain/entities/review_history_query.dart';

class ReviewHistoryState extends Equatable {
  const ReviewHistoryState({
    this.query = const ReviewHistoryQuery(),
    this.items = const [],
    this.total = 0,
    this.totalPages = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final ReviewHistoryQuery query;
  final List<ReviewHistoryItem> items;
  final int total;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final AppFailure? failure;
  final AppFailure? loadMoreFailure;

  bool get hasMore => query.page < totalPages;

  bool get isEmpty => !isLoading && failure == null && items.isEmpty;

  ReviewHistoryState copyWith({
    ReviewHistoryQuery? query,
    List<ReviewHistoryItem>? items,
    int? total,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) {
    return ReviewHistoryState(
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
    query.wordId,
    query.page,
    query.limit,
    [for (final item in items) '${item.id}:${item.result.wireValue}'],
    total,
    totalPages,
    isLoading,
    isLoadingMore,
    failure,
    loadMoreFailure,
  ];
}
