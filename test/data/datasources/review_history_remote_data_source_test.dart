import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_config.dart';
import 'package:lexi_mobile/core/network/api_client.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/core/network/api_response.dart';
import 'package:lexi_mobile/data/datasources/review_remote_data_source.dart';
import 'package:lexi_mobile/domain/entities/review_history_query.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late ReviewRemoteDataSource dataSource;

  const item = {
    'id': 'review-1',
    'wordId': 'word-1',
    'exerciseType': 'MULTIPLE_CHOICE',
    'result': 'CORRECT',
    'responseTimeMs': 2300,
    'hintUsed': false,
    'createdAt': '2026-11-14T09:20:00.000Z',
    'word': {'word': 'lexicon'},
  };

  setUp(() {
    apiClient = MockApiClient();
    dataSource = ReviewRemoteDataSource(apiClient);
  });

  test('loads history with a word filter and pagination', () async {
    when(
      () => apiClient.get(
        '/review/history',
        query: {'page': 2, 'limit': 20, 'wordId': 'word-1'},
        timeout: AppConfig.requestTimeout,
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(
        data: [item],
        meta: PageMeta(page: 2, limit: 20, total: 21, totalPages: 2),
      ),
    );

    final result = await dataSource.getHistory(
      const ReviewHistoryQuery(wordId: ' word-1 ', page: 2),
    );

    expect(result.items.single.word, 'lexicon');
    expect(result.page, 2);
    expect(result.total, 21);
  });

  test('omits a blank word filter', () async {
    when(
      () => apiClient.get(
        '/review/history',
        query: {'page': 1, 'limit': 20},
        timeout: AppConfig.requestTimeout,
      ),
    ).thenAnswer(
      (_) async => const ApiResponse(
        data: [item],
        meta: PageMeta(page: 1, limit: 20, total: 1, totalPages: 1),
      ),
    );

    final result = await dataSource.getHistory(
      const ReviewHistoryQuery(wordId: '  '),
    );

    expect(result.items, hasLength(1));
  });

  test('throws when pagination metadata is missing', () async {
    when(
      () => apiClient.get(
        '/review/history',
        query: {'page': 1, 'limit': 20},
        timeout: AppConfig.requestTimeout,
      ),
    ).thenAnswer((_) async => const ApiResponse(data: [item]));

    await expectLater(
      dataSource.getHistory(const ReviewHistoryQuery()),
      throwsA(isA<ApiException>()),
    );
  });
}
