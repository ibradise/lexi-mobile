import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/vocabulary_query.dart';
import '../../domain/usecases/get_words.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc(this._getWords) : super(const LibraryState()) {
    on<LoadLibrary>(_onLoad);
    on<SearchLibrary>(_onSearch);
    on<FilterLibraryByStatus>(_onFilter);
    on<SortLibrary>(_onSort);
    on<ClearLibraryFilters>(_onClearFilters);
    on<LoadMoreLibrary>(_onLoadMore);
  }

  final GetWords _getWords;
  int _requestId = 0;

  Future<void> _onLoad(LoadLibrary event, Emitter<LibraryState> emit) {
    return _load(emit, state.query.copyWith(page: 1));
  }

  Future<void> _onSearch(SearchLibrary event, Emitter<LibraryState> emit) {
    final search = event.query.trim();
    return _load(
      emit,
      state.query.copyWith(
        search: search.isEmpty ? null : search,
        clearSearch: search.isEmpty,
        page: 1,
      ),
    );
  }

  Future<void> _onFilter(
    FilterLibraryByStatus event,
    Emitter<LibraryState> emit,
  ) {
    return _load(
      emit,
      state.query.copyWith(
        status: event.status,
        clearStatus: event.status == null,
        page: 1,
      ),
    );
  }

  Future<void> _onSort(SortLibrary event, Emitter<LibraryState> emit) {
    return _load(
      emit,
      state.query.copyWith(sort: event.sort, order: event.order, page: 1),
    );
  }

  Future<void> _onClearFilters(
    ClearLibraryFilters event,
    Emitter<LibraryState> emit,
  ) {
    return _load(
      emit,
      state.query.copyWith(clearSearch: true, clearStatus: true, page: 1),
    );
  }

  Future<void> _load(Emitter<LibraryState> emit, VocabularyQuery query) async {
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
      final result = await _getWords(query);
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
    LoadMoreLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    final requestId = ++_requestId;
    final nextQuery = state.query.copyWith(page: state.query.page + 1);

    emit(state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true));

    try {
      final result = await _getWords(nextQuery);
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
