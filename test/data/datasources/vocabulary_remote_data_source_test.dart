import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_config.dart';
import 'package:lexi_mobile/core/network/api_client.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/core/network/api_response.dart';
import 'package:lexi_mobile/data/datasources/vocabulary_remote_data_source.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_query.dart';
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

  group('getWords', () {
    test('sends filters and maps page metadata', () async {
      when(
        () => apiClient.get(
          '/vocabulary',
          query: any(named: 'query'),
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(
          data: [
            {'id': 'word-1', 'word': 'lexicon', 'aiModel': 'gemini-3.5-flash'},
          ],
          meta: PageMeta(page: 2, limit: 10, total: 21, totalPages: 3),
        ),
      );

      final result = await dataSource.getWords(
        const VocabularyQuery(
          search: ' lex ',
          status: LearningStatus.learning,
          sort: VocabularySort.word,
          order: VocabularyOrder.ascending,
          page: 2,
          limit: 10,
        ),
      );

      final query =
          verify(
                () => apiClient.get(
                  '/vocabulary',
                  query: captureAny(named: 'query'),
                  timeout: AppConfig.requestTimeout,
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(query, {
        'search': 'lex',
        'status': 'LEARNING',
        'sort': 'word',
        'order': 'asc',
        'page': 2,
        'limit': 10,
      });
      expect(result.items.single.word, 'lexicon');
      expect(result.page, 2);
      expect(result.totalPages, 3);
    });

    test('omits empty search and null status', () async {
      when(
        () => apiClient.get(
          '/vocabulary',
          query: any(named: 'query'),
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(
          data: [],
          meta: PageMeta(page: 1, limit: 20, total: 0, totalPages: 0),
        ),
      );

      await dataSource.getWords(const VocabularyQuery(search: '   '));

      final query =
          verify(
                () => apiClient.get(
                  '/vocabulary',
                  query: captureAny(named: 'query'),
                  timeout: AppConfig.requestTimeout,
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(query.containsKey('search'), isFalse);
      expect(query.containsKey('status'), isFalse);
    });

    test('throws a parsing exception when metadata is missing', () async {
      when(
        () => apiClient.get(
          '/vocabulary',
          query: any(named: 'query'),
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer((_) async => const ApiResponse(data: []));

      await expectLater(
        dataSource.getWords(const VocabularyQuery()),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'PARSE_ERROR',
          ),
        ),
      );
    });
  });

  group('getWordDetail', () {
    test('encodes the id and maps detail data', () async {
      when(
        () => apiClient.get(
          '/vocabulary/word%2F1',
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(
          data: {'id': 'word/1', 'word': 'lexicon', 'aiModel': 'gemini'},
        ),
      );

      final result = await dataSource.getWordDetail('word/1');

      expect(result.summary.word, 'lexicon');
      expect(result.toEntity().aiReady, isTrue);
    });
  });

  group('deleteWord', () {
    test('requires an archived confirmation', () async {
      when(
        () => apiClient.delete(
          '/vocabulary/word-1',
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer(
        (_) async =>
            const ApiResponse(data: {'id': 'word-1', 'isArchived': true}),
      );

      await dataSource.deleteWord('word-1');

      verify(
        () => apiClient.delete(
          '/vocabulary/word-1',
          timeout: AppConfig.requestTimeout,
        ),
      ).called(1);
    });

    test('throws a parsing exception for an unarchived response', () async {
      when(
        () => apiClient.delete(
          '/vocabulary/word-1',
          timeout: AppConfig.requestTimeout,
        ),
      ).thenAnswer(
        (_) async =>
            const ApiResponse(data: {'id': 'word-1', 'isArchived': false}),
      );

      await expectLater(
        dataSource.deleteWord('word-1'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'PARSE_ERROR',
          ),
        ),
      );
    });
  });

  group('regenerateAi', () {
    test('uses the AI timeout and maps the response', () async {
      when(
        () => apiClient.post(
          '/vocabulary/word-1/regenerate-ai',
          timeout: AppConfig.aiRequestTimeout,
        ),
      ).thenAnswer(
        (_) async => const ApiResponse(
          data: {
            'id': 'word-1',
            'word': 'lexicon',
            'aiModel': null,
            'aiData': null,
          },
        ),
      );

      final result = await dataSource.regenerateAi('word-1');

      expect(result.toEntity().aiReady, isFalse);
    });
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
