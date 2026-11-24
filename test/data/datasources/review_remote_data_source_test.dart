import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_config.dart';
import 'package:lexi_mobile/core/network/api_client.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/core/network/api_response.dart';
import 'package:lexi_mobile/data/datasources/review_remote_data_source.dart';
import 'package:lexi_mobile/domain/entities/review_submission.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late ReviewRemoteDataSource dataSource;

  setUp(() {
    apiClient = MockApiClient();
    dataSource = ReviewRemoteDataSource(apiClient);
  });

  test('getTodayReview loads and maps the queue', () async {
    when(
      () => apiClient.get('/review/today', timeout: AppConfig.requestTimeout),
    ).thenAnswer(
      (_) async => const ApiResponse(
        data: {
          'totalDue': 1,
          'newWords': 0,
          'reviewWords': 1,
          'queue': [
            {
              'wordId': 'word-1',
              'word': 'lexicon',
              'priority': 0.8,
              'knowledgeScore': 0.3,
              'status': 'LEARNING',
              'aiReady': true,
            },
          ],
        },
      ),
    );

    final result = await dataSource.getTodayReview();

    expect(result.totalDue, 1);
    expect(result.queue.single.wordId, 'word-1');
    expect(result.queue.single.aiReady, isTrue);
  });

  test('getExercises encodes the word id', () async {
    when(
      () => apiClient.get(
        '/vocabulary/word%2F1/exercises',
        timeout: AppConfig.requestTimeout,
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(
        data: {
          'wordId': 'word/1',
          'word': 'lexicon',
          'exercises': [
            {
              'id': 'word/1-ex-0',
              'type': 'MULTIPLE_CHOICE',
              'question': 'What does lexicon mean?',
              'options': ['vocabulary', 'flower'],
              'correctAnswer': 'vocabulary',
            },
          ],
        },
      ),
    );

    final result = await dataSource.getExercises('word/1');

    expect(result.wordId, 'word/1');
    expect(result.exercises.single.question, 'What does lexicon mean?');
  });

  test('submitReview sends the answer payload and maps the result', () async {
    when(
      () => apiClient.post(
        '/review/word-1/submit',
        body: any(named: 'body'),
        timeout: AppConfig.requestTimeout,
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(
        data: {
          'review': {
            'id': 'review-1',
            'exerciseType': 'MULTIPLE_CHOICE',
            'result': 'CORRECT',
            'userAnswer': 'vocabulary',
            'correctAnswer': 'vocabulary',
          },
          'learningState': {
            'status': 'STRONG',
            'knowledgeScore': 0.7,
            'easeFactor': 2.5,
            'intervalDays': 1,
            'repetitions': 1,
          },
          'scoreBreakdown': {
            'accuracy': 1,
            'interval': 0.033,
            'responseTime': 0.8,
            'hint': 1,
            'repetition': 0.125,
          },
        },
      ),
    );

    final result = await dataSource.submitReview(
      const ReviewSubmission(
        wordId: 'word-1',
        exerciseId: 'word-1-ex-0',
        userAnswer: 'vocabulary',
        responseTimeMs: 2300,
        submissionId: 'device-1',
      ),
    );

    final body =
        verify(
              () => apiClient.post(
                '/review/word-1/submit',
                body: captureAny(named: 'body'),
                timeout: AppConfig.requestTimeout,
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(body, {
      'exerciseId': 'word-1-ex-0',
      'hintUsed': false,
      'skipped': false,
      'userAnswer': 'vocabulary',
      'responseTimeMs': 2300,
      'submissionId': 'device-1',
    });
    expect(result.review.result.wireValue, 'CORRECT');
    expect(result.learningState.status.wireValue, 'STRONG');
    expect(result.scoreBreakdown.accuracy, 1);
  });

  test('submitReview omits unanswered fields for a skip', () async {
    when(
      () => apiClient.post(
        '/review/word-1/submit',
        body: any(named: 'body'),
        timeout: AppConfig.requestTimeout,
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(
        data: {
          'review': {
            'id': 'review-1',
            'exerciseType': 'MULTIPLE_CHOICE',
            'result': 'SKIPPED',
          },
          'learningState': {
            'status': 'NEW',
            'knowledgeScore': 0,
            'easeFactor': 2.5,
            'intervalDays': 1,
            'repetitions': 0,
          },
          'scoreBreakdown': {
            'accuracy': 0,
            'interval': 0.1,
            'responseTime': 0,
            'hint': 1,
            'repetition': 0,
          },
        },
      ),
    );

    await dataSource.submitReview(
      const ReviewSubmission(
        wordId: 'word-1',
        exerciseId: 'word-1-ex-0',
        skipped: true,
      ),
    );

    final body =
        verify(
              () => apiClient.post(
                '/review/word-1/submit',
                body: captureAny(named: 'body'),
                timeout: AppConfig.requestTimeout,
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(body.containsKey('userAnswer'), isFalse);
    expect(body.containsKey('responseTimeMs'), isFalse);
    expect(body.containsKey('submissionId'), isFalse);
    expect(body['skipped'], isTrue);
  });

  test('throws a parsing exception for an invalid queue payload', () async {
    when(
      () => apiClient.get('/review/today', timeout: AppConfig.requestTimeout),
    ).thenAnswer((_) async => const ApiResponse(data: {'totalDue': 1}));

    await expectLater(
      dataSource.getTodayReview(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'PARSE_ERROR',
        ),
      ),
    );
  });
}
