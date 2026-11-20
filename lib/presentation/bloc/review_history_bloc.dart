import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_history_query.dart';
import '../../domain/usecases/get_review_history.dart';
import 'review_history_event.dart';
import 'review_history_state.dart';

class ReviewHistoryBloc extends Bloc<ReviewHistoryEvent, ReviewHistoryState> {
  ReviewHistoryBloc(this._getReviewHistory)
    : super(const ReviewHistoryState()) {
    on<LoadReviewHistory>(_onLoad);
    on<LoadMoreReviewHistory>(_onLoadMore);
    on<FilterReviewHistoryByWord>(_onFilter);
  }

  final GetReviewHistory _getReviewHistory;
  int _requestId = 0;

  Future<void> _onLoad(
    LoadReviewHistory event,
    Emitter<ReviewHistoryState> emit,
  ) {
    return _load(emit, state.query.copyWith(page: 1));
  }

  Future<void> _onFilter(
    FilterReviewHistoryByWord event,
    Emitter<ReviewHistoryState> emit,
  ) {
    final wordId = event.wordId?.trim();
    return _load(
      emit,
      state.query.copyWith(
        wordId: wordId == null || wordId.isEmpty ? null : wordId,
        clearWordId: wordId == null || wordId.isEmpty,
        page: 1,
      ),
    );
  }

  Future<void> _load(
    Emitter<ReviewHistoryState> emit,
    ReviewHistoryQuery query,
  ) async {
    final requestId = ++_requestId;

    emit(
      state.copyWith(
        query: query,
        items: const [],
        total: 0,
        totalPages: 0,
        isLoading: true,
        isLoadingMore: false,
        clearFailure: true,
        clearLoadMoreFailure: true,
      ),
    );

    try {
      final result = await _getReviewHistory(query);
      if (requestId != _requestId) {
        return;
      }

      emit(
        state.copyWith(
          query: query.copyWith(page: result.page),
          items: result.items,
          total: result.total,
          totalPages: result.totalPages,
          isLoading: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (requestId != _requestId) {
        return;
      }
      emit(state.copyWith(isLoading: false, failure: failure));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreReviewHistory event,
    Emitter<ReviewHistoryState> emit,
  ) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final requestId = ++_requestId;
    final nextQuery = state.query.copyWith(page: state.query.page + 1);

    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));

    try {
      final result = await _getReviewHistory(nextQuery);
      if (requestId != _requestId) {
        return;
      }

      emit(
        state.copyWith(
          query: nextQuery.copyWith(page: result.page),
          items: [...state.items, ...result.items],
          total: result.total,
          totalPages: result.totalPages,
          isLoadingMore: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (requestId != _requestId) {
        return;
      }
      emit(state.copyWith(isLoadingMore: false, loadMoreFailure: failure));
    }
  }
}
