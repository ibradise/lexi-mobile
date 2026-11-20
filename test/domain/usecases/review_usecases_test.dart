import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/review_exercise.dart';
import 'package:lexi_mobile/domain/entities/review_queue.dart';
import 'package:lexi_mobile/domain/entities/review_submission.dart';
import 'package:lexi_mobile/domain/entities/review_submission_result.dart';
import 'package:lexi_mobile/domain/entities/score_breakdown.dart';
import 'package:lexi_mobile/domain/repositories/review_repository.dart';
import 'package:lexi_mobile/domain/usecases/get_review_exercises.dart';
import 'package:lexi_mobile/domain/usecases/get_today_review.dart';
import 'package:lexi_mobile/domain/usecases/submit_review.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

void main() {
  late MockReviewRepository repository;

  const queue = ReviewQueue(
    totalDue: 0,
    newWords: 0,
    reviewWords: 0,
    queue: [],
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
      ),
    ],
  );
  const result = ReviewSubmissionResult(
    review: ReviewEntry(
      id: 'review-1',
      exerciseType: 'MULTIPLE_CHOICE',
      result: ReviewResult.correct,
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
    repository = MockReviewRepository();
  });

  test('GetTodayReview delegates to the repository', () async {
    when(() => repository.getTodayReview()).thenAnswer((_) async => queue);

    final response = await GetTodayReview(repository)();

    expect(response.totalDue, 0);
    verify(() => repository.getTodayReview()).called(1);
  });

  test('GetReviewExercises trims the word id', () async {
    when(() => repository.getExercises('word-1'))
        .thenAnswer((_) async => exerciseSet);

    final response = await GetReviewExercises(repository)(' word-1 ');

    expect(response.firstExercise?.id, 'word-1-ex-0');
  });

  test('GetReviewExercises rejects an empty word id', () {
    expect(
      () => GetReviewExercises(repository)('  '),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('SubmitReview trims fields and bounds response time', () async {
    when(() => repository.submitReview(any())).thenAnswer((_) async => result);

    await SubmitReview(repository)(
      const ReviewSubmission(
        wordId: ' word-1 ',
        exerciseId: ' word-1-ex-0 ',
        userAnswer: 'vocabulary',
        responseTimeMs: 90000,
        submissionId: ' submission-1 ',
      ),
    );

    final submission =
        verify(() => repository.submitReview(captureAny())).captured.single
            as ReviewSubmission;

    expect(submission.wordId, 'word-1');
    expect(submission.exerciseId, 'word-1-ex-0');
    expect(submission.responseTimeMs, 60000);
    expect(submission.submissionId, 'submission-1');
  });

  test('SubmitReview rejects a missing answer', () {
    expect(
      () => SubmitReview(repository)(
        const ReviewSubmission(wordId: 'word-1', exerciseId: 'word-1-ex-0'),
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('SubmitReview allows a skipped answer without a user answer', () async {
    when(() => repository.submitReview(any())).thenAnswer((_) async => result);

    await SubmitReview(repository)(
      const ReviewSubmission(
        wordId: 'word-1',
        exerciseId: 'word-1-ex-0',
        skipped: true,
      ),
    );

    final submission =
        verify(() => repository.submitReview(captureAny())).captured.single
            as ReviewSubmission;

    expect(submission.skipped, isTrue);
    expect(submission.userAnswer, isNull);
  });
}
