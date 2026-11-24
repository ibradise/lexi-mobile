import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/usecases/get_today_review.dart';
import 'review_queue_event.dart';
import 'review_queue_state.dart';

class ReviewQueueBloc extends Bloc<ReviewQueueEvent, ReviewQueueState> {
  ReviewQueueBloc(this._getTodayReview) : super(const ReviewQueueState()) {
    on<LoadReviewQueue>(_onLoad);
  }

  final GetTodayReview _getTodayReview;
  int _requestId = 0;

  Future<void> _onLoad(
    LoadReviewQueue event,
    Emitter<ReviewQueueState> emit,
  ) async {
    final requestId = ++_requestId;
    emit(state.copyWith(isLoading: true, clearFailure: true));

    try {
      final queue = await _getTodayReview();
      if (requestId != _requestId) {
        return;
      }
      emit(state.copyWith(queue: queue, isLoading: false, clearFailure: true));
    } on AppFailure catch (failure) {
      if (requestId != _requestId) {
        return;
      }
      emit(state.copyWith(isLoading: false, failure: failure));
    }
  }
}
