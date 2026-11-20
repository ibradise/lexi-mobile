import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_entry.dart';
import '../../domain/entities/review_submission.dart';
import '../../domain/usecases/get_review_exercises.dart';
import '../../domain/usecases/get_today_review.dart';
import '../../domain/usecases/submit_review.dart';
import 'review_session_event.dart';
import 'review_session_state.dart';

class ReviewSessionBloc extends Bloc<ReviewSessionEvent, ReviewSessionState> {
  ReviewSessionBloc(
    this._getTodayReview,
    this._getExercises,
    this._submitReview,
  ) : super(const ReviewSessionState()) {
    on<StartReviewSession>(_onStart);
    on<SelectReviewAnswer>(_onSelect);
    on<SubmitReviewAnswer>(_onSubmitAnswer);
    on<SkipReviewQuestion>(_onSkip);
    on<ContinueReviewSession>(_onContinue);
    on<RetryReviewSession>(_onRetry);
  }

  final GetTodayReview _getTodayReview;
  final GetReviewExercises _getExercises;
  final SubmitReview _submitReview;

  DateTime? _shownAt;
  String? _submissionId;
  int? _responseTimeMs;
  bool _pendingSkipped = false;
  int _submissionSequence = 0;

  Future<void> _onStart(
    StartReviewSession event,
    Emitter<ReviewSessionState> emit,
  ) async {
    emit(const ReviewSessionState(status: ReviewSessionStatus.loading));

    try {
      final queue = await _getTodayReview();
      final readyItems = [
        for (final item in queue.queue)
          if (item.aiReady) item,
      ];
      final pendingAiCount = queue.queue.length - readyItems.length;

      if (readyItems.isEmpty) {
        emit(
          ReviewSessionState(
            status: ReviewSessionStatus.empty,
            sessionItems: const [],
            pendingAiCount: pendingAiCount,
          ),
        );
        return;
      }

      emit(
        ReviewSessionState(
          status: ReviewSessionStatus.loading,
          sessionItems: readyItems,
          pendingAiCount: pendingAiCount,
        ),
      );
      await _loadExercise(emit);
    } on AppFailure catch (failure) {
      emit(
        ReviewSessionState(
          status: ReviewSessionStatus.failure,
          failure: failure,
          failureStep: ReviewSessionFailureStep.queue,
        ),
      );
    }
  }

  void _onSelect(SelectReviewAnswer event, Emitter<ReviewSessionState> emit) {
    if (state.status != ReviewSessionStatus.answering) {
      return;
    }
    emit(state.copyWith(selectedAnswer: event.answer));
  }

  Future<void> _onSubmitAnswer(
    SubmitReviewAnswer event,
    Emitter<ReviewSessionState> emit,
  ) {
    return _submit(emit, skipped: false);
  }

  Future<void> _onSkip(
    SkipReviewQuestion event,
    Emitter<ReviewSessionState> emit,
  ) {
    return _submit(emit, skipped: true);
  }

  Future<void> _onContinue(
    ContinueReviewSession event,
    Emitter<ReviewSessionState> emit,
  ) async {
    if (state.status != ReviewSessionStatus.feedback) {
      return;
    }

    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.sessionItems.length) {
      emit(
        state.copyWith(
          status: ReviewSessionStatus.completed,
          clearExercise: true,
          clearSelectedAnswer: true,
          clearResult: true,
          clearFailure: true,
          clearFailureStep: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ReviewSessionStatus.loading,
        currentIndex: nextIndex,
        clearExercise: true,
        clearSelectedAnswer: true,
        clearResult: true,
        clearFailure: true,
        clearFailureStep: true,
      ),
    );
    await _loadExercise(emit);
  }

  Future<void> _onRetry(
    RetryReviewSession event,
    Emitter<ReviewSessionState> emit,
  ) async {
    switch (state.failureStep) {
      case ReviewSessionFailureStep.queue:
        await _onStart(const StartReviewSession(), emit);
        return;
      case ReviewSessionFailureStep.exercise:
        emit(
          state.copyWith(
            status: ReviewSessionStatus.loading,
            clearFailure: true,
            clearFailureStep: true,
          ),
        );
        await _loadExercise(emit);
        return;
      case ReviewSessionFailureStep.submit:
        await _submit(emit, skipped: _pendingSkipped);
        return;
      case null:
        return;
    }
  }

  Future<void> _loadExercise(Emitter<ReviewSessionState> emit) async {
    var index = state.currentIndex;
    var pendingAiCount = state.pendingAiCount;

    while (index < state.sessionItems.length) {
      final item = state.sessionItems[index];

      try {
        final exerciseSet = await _getExercises(item.wordId);
        final exercise = exerciseSet.firstExercise;

        if (exercise == null) {
          index += 1;
          continue;
        }

        _shownAt = DateTime.now();
        _responseTimeMs = null;
        _pendingSkipped = false;
        _submissionId =
            'review-${DateTime.now().microsecondsSinceEpoch}-'
            '${item.wordId}-${++_submissionSequence}';

        emit(
          state.copyWith(
            status: ReviewSessionStatus.answering,
            currentIndex: index,
            exercise: exercise,
            clearSelectedAnswer: true,
            clearResult: true,
            clearFailure: true,
            clearFailureStep: true,
            pendingAiCount: pendingAiCount,
          ),
        );
        return;
      } on AiNotReadyFailure {
        pendingAiCount += 1;
        index += 1;
      } on AppFailure catch (failure) {
        emit(
          state.copyWith(
            status: ReviewSessionStatus.failure,
            currentIndex: index,
            failure: failure,
            failureStep: ReviewSessionFailureStep.exercise,
            clearExercise: true,
            clearSelectedAnswer: true,
            clearResult: true,
            pendingAiCount: pendingAiCount,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        status: ReviewSessionStatus.completed,
        currentIndex: index,
        clearExercise: true,
        clearSelectedAnswer: true,
        clearResult: true,
        clearFailure: true,
        clearFailureStep: true,
        pendingAiCount: pendingAiCount,
      ),
    );
  }

  Future<void> _submit(
    Emitter<ReviewSessionState> emit, {
    required bool skipped,
  }) async {
    final item = state.currentItem;
    final exercise = state.exercise;

    if (item == null ||
        exercise == null ||
        state.status == ReviewSessionStatus.submitting ||
        (!skipped && state.selectedAnswer == null)) {
      return;
    }

    _pendingSkipped = skipped;
    _responseTimeMs ??= _elapsedMs();
    final responseTimeMs = _responseTimeMs;

    emit(
      state.copyWith(
        status: ReviewSessionStatus.submitting,
        clearFailure: true,
        clearFailureStep: true,
      ),
    );

    try {
      final result = await _submitReview(
        ReviewSubmission(
          wordId: item.wordId,
          exerciseId: exercise.id,
          userAnswer: skipped ? null : state.selectedAnswer,
          responseTimeMs: responseTimeMs,
          skipped: skipped,
          submissionId: _submissionId,
        ),
      );

      final correct = result.review.result == ReviewResult.correct;
      final incorrect = result.review.result == ReviewResult.incorrect;

      emit(
        state.copyWith(
          status: ReviewSessionStatus.feedback,
          result: result,
          answeredCount: state.answeredCount + 1,
          correctCount: state.correctCount + (correct ? 1 : 0),
          incorrectCount: state.incorrectCount + (incorrect ? 1 : 0),
          skippedCount:
              state.skippedCount +
              (result.review.result == ReviewResult.skipped ? 1 : 0),
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: ReviewSessionStatus.failure,
          failure: failure,
          failureStep: ReviewSessionFailureStep.submit,
        ),
      );
    }
  }

  int _elapsedMs() {
    final shownAt = _shownAt;
    if (shownAt == null) {
      return 0;
    }
    return DateTime.now().difference(shownAt).inMilliseconds.clamp(0, 60000);
  }
}
