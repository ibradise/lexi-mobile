import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_config.dart';
import 'package:lexi_mobile/core/network/api_client.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/core/network/api_response.dart';
import 'package:lexi_mobile/data/datasources/vocabulary_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late VocabularyRemoteDataSource dataSource;

  setUp(() {
    apiClient = MockApiClient();
    dataSource = VocabularyRemoteDataSource(apiClient);
  });

  group('addWord', () {
    test(
      'sends only populated optional fields and uses the AI timeout',
      () async {
        when(
          () => apiClient.post(
            '/vocabulary',
            body: any(named: 'body'),
            timeout: AppConfig.aiRequestTimeout,
          ),
        ).thenAnswer(
          (_) async => const ApiResponse(
            data: {
              'id': 'word-1',
              'word': 'lexicon',
              'aiModel': 'gemini-3.5-flash',
            },
          ),
        );

        final result = await dataSource.addWord(
          word: 'lexicon',
          context: 'A sentence.',
          sourceTitle: 'Example article',
          sourceUrl: 'https://example.com/article',
        );

        final body =
            verify(
                  () => apiClient.post(
                    '/vocabulary',
                    body: captureAny(named: 'body'),
                    timeout: AppConfig.aiRequestTimeout,
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(body, {
          'word': 'lexicon',
          'sourceContext': 'A sentence.',
          'sourceTitle': 'Example article',
          'sourceUrl': 'https://example.com/article',
        });
        expect(result.aiReady, isTrue);
      },
    );

    test('omits null optional fields from the request body', () async {
      when(
        () => apiClient.post(
          '/vocabulary',
          body: any(named: 'body'),
          timeout: AppConfig.aiRequestTimeout,
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(
          data: {'id': 'word-1', 'word': 'lexicon', 'aiModel': null},
        ),
      );

      await dataSource.addWord(word: 'lexicon');

      final body =
          verify(
                () => apiClient.post(
                  '/vocabulary',
                  body: captureAny(named: 'body'),
                  timeout: AppConfig.aiRequestTimeout,
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(body, {'word': 'lexicon'});
    });

    test(
      'throws a parsing exception for an unexpected response shape',
      () async {
        when(
          () => apiClient.post(
            '/vocabulary',
            body: any(named: 'body'),
            timeout: AppConfig.aiRequestTimeout,
          ),
        ).thenAnswer((_) async => const ApiResponse(data: 'unexpected'));

        await expectLater(
          dataSource.addWord(word: 'lexicon'),
          throwsA(
            isA<ApiException>().having(
              (error) => error.code,
              'code',
              'PARSE_ERROR',
            ),
          ),
        );
      },
    );
  });

  group('addWords', () {
    test('sends the words array with the standard timeout', () async {
      when(
        () => apiClient.post(
          '/vocabulary',
          body: any(named: 'body'),
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(
          data: {
            'added': [
              {'id': 'word-1', 'word': 'lexicon', 'status': 'PENDING'},
            ],
            'duplicates': ['syntax'],
            'invalid': [],
          },
        ),
      );

      final result = await dataSource.addWords(['lexicon, syntax']);

      final body =
          verify(
                () => apiClient.post(
                  '/vocabulary',
                  body: captureAny(named: 'body'),
                  timeout: AppConfig.requestTimeout,
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(body, {
        'words': ['lexicon, syntax'],
      });
      expect(result.added.single.word, 'lexicon');
      expect(result.duplicates, ['syntax']);
    });
  });
}
