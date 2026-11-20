import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
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
import 'package:lexi_mobile/presentation/pages/review_session_page.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTodayReview extends Mock implements GetTodayReview {}

class MockGetReviewExercises extends Mock implements GetReviewExercises {}

class MockSubmitReview extends Mock implements SubmitReview {}

void main() {
  late MockGetTodayReview getTodayReview;
  late MockGetReviewExercises getExercises;
  late MockSubmitReview submitReview;

  const queue = ReviewQueue(
    totalDue: 1,
    newWords: 0,
    reviewWords: 1,
    queue: [
      ReviewQueueItem(
        wordId: 'word-1',
        word: 'lexicon',
        priority: 0.9,
        knowledgeScore: 0.2,
        status: LearningStatus.learning,
        aiReady: true,
      ),
    ],
  );
  const exerciseSet = ReviewExerciseSet(
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
  const result = ReviewSubmissionResult(
    review: ReviewEntry(
      id: 'review-1',
      exerciseType: 'MULTIPLE_CHOICE',
      result: ReviewResult.correct,
      correctAnswer: 'vocabulary',
    ),
    learningState: LearningState(
      status: LearningStatus.strong,
      knowledgeScore: 0.7,
      easeFactor: 2.5,
      intervalDays: 1,
      repetitions: 1,
    ),
    scoreBreakdown: ScoreBreakdown(
      accuracy: 1,
      interval: 0.1,
      responseTime: 0.8,
      hint: 1,
      repetition: 0.1,
    ),
  );

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

  ReviewSessionBloc buildBloc() {
    return ReviewSessionBloc(getTodayReview, getExercises, submitReview)
      ..add(const StartReviewSession());
  }

  Future<void> pumpSession(WidgetTester tester, ReviewSessionBloc bloc) async {
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<ReviewSessionBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReviewSessionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a question and feedback after submitting', (tester) async {
    when(() => getTodayReview()).thenAnswer((_) async => queue);
    when(() => getExercises('word-1')).thenAnswer((_) async => exerciseSet);
    when(() => submitReview(any())).thenAnswer((_) async => result);

    await pumpSession(tester, buildBloc());

    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('What does lexicon mean?'), findsOneWidget);
    expect(find.byKey(const Key('reviewOption-0')), findsOneWidget);
    expect(find.byKey(const Key('reviewSubmitButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reviewOption-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('reviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Correct answer: vocabulary'), findsOneWidget);
    expect(find.text('A lexicon is vocabulary.'), findsOneWidget);
    expect(find.byKey(const Key('reviewContinueButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reviewContinueButton')));
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.byKey(const Key('reviewFinishButton')), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing is AI-ready', (tester) async {
    when(() => getTodayReview()).thenAnswer(
      (_) async => const ReviewQueue(
        totalDue: 1,
        newWords: 1,
        reviewWords: 0,
        queue: [
          ReviewQueueItem(
            wordId: 'word-1',
            word: 'lexicon',
            priority: 1,
            knowledgeScore: 0,
            status: LearningStatus.newWord,
            aiReady: false,
          ),
        ],
      ),
    );

    await pumpSession(tester, buildBloc());

    expect(find.text("You're all caught up"), findsOneWidget);
    expect(
      find.text('Some words are still waiting for AI content.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reviewEmptyCloseButton')), findsOneWidget);
  });
}
