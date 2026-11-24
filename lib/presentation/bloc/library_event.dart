import 'package:equatable/equatable.dart';

import '../../domain/entities/learning_state.dart';
import '../../domain/entities/vocabulary_query.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadLibrary extends LibraryEvent {
  const LoadLibrary();
}

final class SearchLibrary extends LibraryEvent {
  const SearchLibrary(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class FilterLibraryByStatus extends LibraryEvent {
  const FilterLibraryByStatus(this.status);

  final LearningStatus? status;

  @override
  List<Object?> get props => [status];
}

final class SortLibrary extends LibraryEvent {
  const SortLibrary(this.sort, this.order);

  final VocabularySort sort;
  final VocabularyOrder order;

  @override
  List<Object?> get props => [sort, order];
}

final class ClearLibraryFilters extends LibraryEvent {
  const ClearLibraryFilters();
}

final class LoadMoreLibrary extends LibraryEvent {
  const LoadMoreLibrary();
}
