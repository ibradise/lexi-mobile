import 'package:equatable/equatable.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/review_exercise.dart';
import '../../domain/entities/review_queue.dart';
import '../../domain/entities/review_submission_result.dart';

enum ReviewSessionStatus {
  idle,
  loading,
  answering,
  submitting,
  feedback,
  empty,
  completed,
  failure,
}

enum ReviewSessionFailureStep { queue, exercise, submit }

class ReviewSessionState extends Equatable {
  const ReviewSessionState({
    this.status = ReviewSessionStatus.idle,
    this.sessionItems = const [],
    this.currentIndex = 0,
    this.exercise,
    this.selectedAnswer,
    this.result,
    this.failure,
    this.failureStep,
    this.answeredCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.skippedCount = 0,
    this.pendingAiCount = 0,
  });

  final ReviewSessionStatus status;
  final List<ReviewQueueItem> sessionItems;
  final int currentIndex;
  final ReviewExercise? exercise;
  final String? selectedAnswer;
  final ReviewSubmissionResult? result;
  final AppFailure? failure;
  final ReviewSessionFailureStep? failureStep;
  final int answeredCount;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final int pendingAiCount;

  int get totalInSession => sessionItems.length;

  ReviewQueueItem? get currentItem {
    if (currentIndex < 0 || currentIndex >= sessionItems.length) {
      return null;
    }
    return sessionItems[currentIndex];
  }

  bool get isActive => switch (status) {
    ReviewSessionStatus.answering ||
    ReviewSessionStatus.submitting ||
    ReviewSessionStatus.feedback => true,
    _ => false,
  };

  bool get canSubmit =>
      status == ReviewSessionStatus.answering && selectedAnswer != null;

  bool get isLastQuestion => currentIndex >= sessionItems.length - 1;

  double get progress {
    if (totalInSession == 0) {
      return 0;
    }
    final completed =
        currentIndex + (status == ReviewSessionStatus.feedback ? 1 : 0);
    return (completed / totalInSession).clamp(0, 1).toDouble();
  }

  ReviewSessionState copyWith({
    ReviewSessionStatus? status,
    List<ReviewQueueItem>? sessionItems,
    int? currentIndex,
    ReviewExercise? exercise,
    bool clearExercise = false,
    String? selectedAnswer,
    bool clearSelectedAnswer = false,
    ReviewSubmissionResult? result,
    bool clearResult = false,
    AppFailure? failure,
    bool clearFailure = false,
    ReviewSessionFailureStep? failureStep,
    bool clearFailureStep = false,
    int? answeredCount,
    int? correctCount,
    int? incorrectCount,
    int? skippedCount,
    int? pendingAiCount,
  }) {
    return ReviewSessionState(
      status: status ?? this.status,
      sessionItems: sessionItems ?? this.sessionItems,
      currentIndex: currentIndex ?? this.currentIndex,
      exercise: clearExercise ? null : exercise ?? this.exercise,
      selectedAnswer: clearSelectedAnswer
          ? null
          : selectedAnswer ?? this.selectedAnswer,
      result: clearResult ? null : result ?? this.result,
      failure: clearFailure ? null : failure ?? this.failure,
      failureStep: clearFailureStep ? null : failureStep ?? this.failureStep,
      answeredCount: answeredCount ?? this.answeredCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      skippedCount: skippedCount ?? this.skippedCount,
      pendingAiCount: pendingAiCount ?? this.pendingAiCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    [for (final item in sessionItems) item.wordId],
    currentIndex,
    exercise?.id,
    selectedAnswer,
    result?.review.id,
    failure,
    failureStep,
    answeredCount,
    correctCount,
    incorrectCount,
    skippedCount,
    pendingAiCount,
  ];
}
