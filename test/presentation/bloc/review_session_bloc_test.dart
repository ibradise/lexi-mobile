import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/review_exercise.dart';
import 'package:lexi_mobile/domain/entities/review_queue.dart';
import 'package:lexi_mobile/domain/entities/review_submission.dart';
import 'package:lexi_mobile/domain/entities/review_submission_result.dart';
import 'package:lexi_mobile/domain/entities/score_breakdown.dart';
import 'package:lexi_mobile/domain/usecases/get_review_exercises.dart';
import 'package:lexi_mobile/domain/usecases/get_today_review.dart';
import 'package:lexi_mobile/domain/usecases/submit_review.dart';
import 'package:lexi_mobile/presentation/bloc/review_session_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/review_session_event.dart';
import 'package:lexi_mobile/presentation/bloc/review_session_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTodayReview extends Mock implements GetTodayReview {}

class MockGetReviewExercises extends Mock implements GetReviewExercises {}

class MockSubmitReview extends Mock implements SubmitReview {}

void main() {
  late MockGetTodayReview getTodayReview;
  late MockGetReviewExercises getExercises;
  late MockSubmitReview submitReview;

  const readyItem = ReviewQueueItem(
    wordId: 'word-1',
    word: 'lexicon',
    priority: 0.9,
    knowledgeScore: 0.2,
    status: LearningStatus.learning,
    aiReady: true,
  );
  const pendingItem = ReviewQueueItem(
    wordId: 'word-2',
    word: 'syntax',
    priority: 0.5,
    knowledgeScore: 0,
    status: LearningStatus.newWord,
    aiReady: false,
  );
  const secondReadyItem = ReviewQueueItem(
    wordId: 'word-3',
    word: 'semantics',
    priority: 0.4,
    knowledgeScore: 0.5,
    status: LearningStatus.familiar,
    aiReady: true,
  );
  const queue = ReviewQueue(
    totalDue: 3,
    newWords: 1,
    reviewWords: 2,
    queue: [readyItem, pendingItem, secondReadyItem],
  );
  const firstExercise = ReviewExerciseSet(
    wordId: 'word-1',
    word: 'lexicon',
    exercises: [
      ReviewExercise(
        id: 'word-1-ex-0',
        type: 'MULTIPLE_CHOICE',
        question: 'What does lexicon mean?',
        options: ['vocabulary', 'flower'],
        correctAnswer: 'vocabulary',
        explanation: 'A lexicon is vocabulary.',
      ),
    ],
  );
  const secondExercise = ReviewExerciseSet(
    wordId: 'word-3',
    word: 'semantics',
    exercises: [
      ReviewExercise(
        id: 'word-3-ex-0',
        type: 'MULTIPLE_CHOICE',
        question: 'What does semantics mean?',
        options: ['meaning', 'sound'],
        correctAnswer: 'meaning',
      ),
    ],
  );

  ReviewSubmissionResult buildResult({
    required String id,
    required ReviewResult result,
  }) {
    return ReviewSubmissionResult(
      review: ReviewEntry(
        id: id,
        exerciseType: 'MULTIPLE_CHOICE',
        result: result,
      ),
      learningState: const LearningState(
        status: LearningStatus.strong,
        knowledgeScore: 0.7,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 1,
      ),
      scoreBreakdown: const ScoreBreakdown(
        accuracy: 1,
        interval: 0.1,
        responseTime: 0.8,
        hint: 1,
        repetition: 0.1,
      ),
    );
  }

  ReviewSessionBloc buildBloc() {
    return ReviewSessionBloc(getTodayReview, getExercises, submitReview);
  }

  setUpAll(() {
    registerFallbackValue(
      const ReviewSubmission(wordId: 'word-1', exerciseId: 'exercise-1'),
    );
  });

  setUp(() {
    getTodayReview = MockGetTodayReview();
    getExercises = MockGetReviewExercises();
    submitReview = MockSubmitReview();
  });

  test('starts with AI-ready words and reports pending ones', () async {
    when(() => getTodayReview()).thenAnswer((_) async => queue);
    when(() => getExercises('word-1')).thenAnswer((_) async => firstExercise);
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const StartReviewSession());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ReviewSessionStatus.answering);
    expect(bloc.state.totalInSession, 2);
    expect(bloc.state.currentItem?.wordId, 'word-1');
    expect(bloc.state.pendingAiCount, 1);
    expect(bloc.state.exercise?.id, 'word-1-ex-0');
    verifyNever(() => getExercises('word-2'));
  });

  test('submits an answer, continues, and completes the session', () async {
    when(() => getTodayReview()).thenAnswer((_) async => queue);
    when(() => getExercises('word-1')).thenAnswer((_) async => firstExercise);
    when(() => getExercises('word-3')).thenAnswer((_) async => secondExercise);
    when(() => submitReview(any())).thenAnswer((invocation) async {
      final submission =
          invocation.positionalArguments.single as ReviewSubmission;
      if (submission.skipped) {
        return buildResult(id: 'review-2', result: ReviewResult.skipped);
      }
      return buildResult(id: 'review-1', result: ReviewResult.correct);
    });
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const StartReviewSession());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SelectReviewAnswer('vocabulary'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedAnswer, 'vocabulary');

    bloc.add(const SubmitReviewAnswer());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, ReviewSessionStatus.feedback);
    expect(bloc.state.correctCount, 1);
    expect(bloc.state.result?.review.result, ReviewResult.correct);

    bloc.add(const ContinueReviewSession());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, ReviewSessionStatus.answering);
    expect(bloc.state.currentItem?.wordId, 'word-3');

    bloc.add(const SkipReviewQuestion());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, ReviewSessionStatus.feedback);
    expect(bloc.state.skippedCount, 1);

    bloc.add(const ContinueReviewSession());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, ReviewSessionStatus.completed);
    expect(bloc.state.answeredCount, 2);
    expect(bloc.state.correctCount, 1);
    expect(bloc.state.skippedCount, 1);
  });

  test('reports an empty session when nothing is AI-ready', () async {
    when(() => getTodayReview()).thenAnswer(
      (_) async => const ReviewQueue(
        totalDue: 1,
        newWords: 1,
        reviewWords: 0,
        queue: [pendingItem],
      ),
    );
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const StartReviewSession());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ReviewSessionStatus.empty);
    expect(bloc.state.pendingAiCount, 1);
  });

  test('keeps the exercise and retries a failed submission', () async {
    when(() => getTodayReview()).thenAnswer((_) async => queue);
    when(() => getExercises('word-1')).thenAnswer((_) async => firstExercise);
    var attempts = 0;
    when(() => submitReview(any())).thenAnswer((_) async {
      if (attempts++ == 0) {
        throw const NetworkFailure();
      }
      return buildResult(id: 'review-1', result: ReviewResult.correct);
    });
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const StartReviewSession());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SelectReviewAnswer('vocabulary'));
    bloc.add(const SubmitReviewAnswer());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ReviewSessionStatus.failure);
    expect(bloc.state.failureStep, ReviewSessionFailureStep.submit);
    expect(bloc.state.exercise?.id, 'word-1-ex-0');

    bloc.add(const RetryReviewSession());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ReviewSessionStatus.feedback);
    expect(bloc.state.correctCount, 1);
  });

  blocTest<ReviewSessionBloc, ReviewSessionState>(
    'emits a queue failure when today\'s review cannot load',
    build: () {
      when(() => getTodayReview()).thenThrow(const NetworkFailure());
      return buildBloc();
    },
    act: (bloc) => bloc.add(const StartReviewSession()),
    expect: () => [
      isA<ReviewSessionState>().having(
        (state) => state.status,
        'status',
        ReviewSessionStatus.loading,
      ),
      isA<ReviewSessionState>()
          .having(
            (state) => state.status,
            'status',
            ReviewSessionStatus.failure,
          )
          .having(
            (state) => state.failureStep,
            'step',
            ReviewSessionFailureStep.queue,
          ),
    ],
  );
}
