import 'package:equatable/equatable.dart';

sealed class ReviewHistoryEvent extends Equatable {
  const ReviewHistoryEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadReviewHistory extends ReviewHistoryEvent {
  const LoadReviewHistory();
}

final class LoadMoreReviewHistory extends ReviewHistoryEvent {
  const LoadMoreReviewHistory();
}

final class FilterReviewHistoryByWord extends ReviewHistoryEvent {
  const FilterReviewHistoryByWord(this.wordId);

  final String? wordId;

  @override
  List<Object?> get props => [wordId];
}
