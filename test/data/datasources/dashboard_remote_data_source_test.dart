import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_config.dart';
import 'package:lexi_mobile/core/network/api_client.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/core/network/api_response.dart';
import 'package:lexi_mobile/data/datasources/dashboard_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late DashboardRemoteDataSource dataSource;

  const data = {
    'todayReview': {
      'due': 8,
      'newWords': 4,
      'needAttention': 2,
      'becomingStrong': 3,
    },
    'weakestWords': [
      {'wordId': 'word-1', 'word': 'lexicon', 'knowledgeScore': 0.15},
    ],
    'stats': {
      'totalWords': 42,
      'new': 4,
      'learning': 12,
      'familiar': 10,
      'strong': 9,
      'mastered': 7,
      'reviewsToday': 5,
      'accuracyLast7Days': 0.8,
      'currentStreak': 0,
    },
  };

  setUp(() {
    apiClient = MockApiClient();
    dataSource = DashboardRemoteDataSource(apiClient);
  });

  test('loads the dashboard endpoint', () async {
    when(() => apiClient.get('/dashboard', timeout: AppConfig.requestTimeout))
        .thenAnswer((_) async => const ApiResponse(data: data));

    final result = await dataSource.getDashboard();

    expect(result.todayReview.due, 8);
    expect(result.stats.totalWords, 42);
    expect(result.weakestWords.single.word, 'lexicon');
  });

  test('rejects a non-map dashboard payload', () async {
    when(() => apiClient.get('/dashboard', timeout: AppConfig.requestTimeout))
        .thenAnswer((_) async => const ApiResponse(data: []));

    await expectLater(dataSource.getDashboard(), throwsA(isA<ApiException>()));
  });

  test('rejects incomplete dashboard data', () async {
    when(() => apiClient.get('/dashboard', timeout: AppConfig.requestTimeout))
        .thenAnswer(
          (_) async => const ApiResponse(
            data: {'todayReview': <String, dynamic>{}, 'weakestWords': []},
          ),
        );

    await expectLater(dataSource.getDashboard(), throwsA(isA<ApiException>()));
  });
}
