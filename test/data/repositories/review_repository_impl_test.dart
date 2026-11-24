import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/data/datasources/review_remote_data_source.dart';
import 'package:lexi_mobile/data/models/learning_state_model.dart';
import 'package:lexi_mobile/data/models/review_entry_model.dart';
import 'package:lexi_mobile/data/models/review_exercise_model.dart';
import 'package:lexi_mobile/data/models/review_queue_model.dart';
import 'package:lexi_mobile/data/models/review_submission_result_model.dart';
import 'package:lexi_mobile/data/repositories/review_repository_impl.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/review_submission.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRemoteDataSource extends Mock
    implements ReviewRemoteDataSource {}

void main() {
  late MockReviewRemoteDataSource remoteDataSource;
  late ReviewRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const ReviewSubmission(wordId: 'word-1', exerciseId: 'exercise-1'),
    );
  });

  setUp(() {
    remoteDataSource = MockReviewRemoteDataSource();
    repository = ReviewRepositoryImpl(remoteDataSource);
  });

  test('maps a review queue to domain entities', () async {
    when(() => remoteDataSource.getTodayReview()).thenAnswer(
      (_) async => const ReviewQueueModel(
        totalDue: 1,
        newWords: 0,
        reviewWords: 1,
        queue: [
          ReviewQueueItemModel(
            wordId: 'word-1',
            word: 'lexicon',
            priority: 0.8,
            knowledgeScore: 0.2,
            status: LearningStatus.learning,
            aiReady: true,
          ),
        ],
      ),
    );

    final result = await repository.getTodayReview();

    expect(result.queue.single.word, 'lexicon');
    expect(result.queue.single.status, LearningStatus.learning);
    expect(result.queue.single.aiReady, isTrue);
  });

  test('maps an exercise set to domain entities', () async {
    when(() => remoteDataSource.getExercises('word-1')).thenAnswer(
      (_) async => const ReviewExerciseSetModel(
        wordId: 'word-1',
        word: 'lexicon',
        exercises: [
          ReviewExerciseModel(
            id: 'word-1-ex-0',
            type: 'MULTIPLE_CHOICE',
            question: 'What does lexicon mean?',
            options: ['vocabulary', 'flower'],
            correctAnswer: 'vocabulary',
          ),
        ],
      ),
    );

    final result = await repository.getExercises('word-1');

    expect(result.firstExercise?.id, 'word-1-ex-0');
    expect(result.firstExercise?.options, ['vocabulary', 'flower']);
  });

  test('maps a submission result to domain entities', () async {
    when(() => remoteDataSource.submitReview(any())).thenAnswer(
      (_) async => const ReviewSubmissionResultModel(
        review: ReviewEntryModel(
          id: 'review-1',
          exerciseType: 'MULTIPLE_CHOICE',
          result: ReviewResult.correct,
        ),
        learningState: LearningStateModel(
          status: LearningStatus.strong,
          knowledgeScore: 0.7,
          easeFactor: 2.5,
          intervalDays: 1,
          repetitions: 1,
        ),
        scoreBreakdown: ScoreBreakdownModel(
          accuracy: 1,
          interval: 0.1,
          responseTime: 0.8,
          hint: 1,
          repetition: 0.2,
        ),
      ),
    );

    final result = await repository.submitReview(
      const ReviewSubmission(
        wordId: 'word-1',
        exerciseId: 'word-1-ex-0',
        userAnswer: 'vocabulary',
      ),
    );

    expect(result.review.result, ReviewResult.correct);
    expect(result.learningState.status, LearningStatus.strong);
    expect(result.scoreBreakdown.accuracy, 1);
  });

  test('translates remote failures into AppFailure', () async {
    when(() => remoteDataSource.getTodayReview()).thenThrow(
      const ApiException(
        code: 'NOT_FOUND',
        message: 'Review queue not found',
        statusCode: 404,
      ),
    );

    await expectLater(
      repository.getTodayReview(),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
