import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_queue.dart';

class ReviewQueueState extends Equatable {
  const ReviewQueueState({this.queue, this.isLoading = false, this.failure});

  final ReviewQueue? queue;
  final bool isLoading;
  final AppFailure? failure;

  bool get isEmpty => queue != null && queue!.isEmpty;

  ReviewQueueState copyWith({
    ReviewQueue? queue,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ReviewQueueState(
      queue: queue ?? this.queue,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [queue, isLoading, failure];
}
