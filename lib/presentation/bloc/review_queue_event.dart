import 'package:equatable/equatable.dart';

sealed class ReviewQueueEvent extends Equatable {
  const ReviewQueueEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadReviewQueue extends ReviewQueueEvent {
  const LoadReviewQueue();
}
