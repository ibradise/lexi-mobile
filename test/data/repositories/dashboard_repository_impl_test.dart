import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/data/datasources/dashboard_remote_data_source.dart';
import 'package:lexi_mobile/data/models/dashboard_model.dart';
import 'package:lexi_mobile/data/repositories/dashboard_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRemoteDataSource extends Mock
    implements DashboardRemoteDataSource {}

void main() {
  late MockDashboardRemoteDataSource remoteDataSource;
  late DashboardRepositoryImpl repository;

  const model = DashboardModel(
    todayReview: DashboardTodayReviewModel(
      due: 3,
      newWords: 1,
      needAttention: 1,
      becomingStrong: 1,
    ),
    weakestWords: [
      WeakestWordModel(wordId: 'word-1', word: 'lexicon', knowledgeScore: 0.2),
    ],
    stats: DashboardStatsModel(
      totalWords: 10,
      newWords: 2,
      learning: 3,
      familiar: 2,
      strong: 2,
      mastered: 1,
      reviewsToday: 4,
      accuracyLast7Days: 0.75,
      currentStreak: 2,
    ),
  );

  setUp(() {
    remoteDataSource = MockDashboardRemoteDataSource();
    repository = DashboardRepositoryImpl(remoteDataSource);
  });

  test('maps dashboard models to domain entities', () async {
    when(() => remoteDataSource.getDashboard()).thenAnswer((_) async => model);

    final result = await repository.getDashboard();

    expect(result.todayReview.due, 3);
    expect(result.stats.totalWords, 10);
    expect(result.weakestWords.single.word, 'lexicon');
  });

  test('translates remote failures into AppFailure', () async {
    when(() => remoteDataSource.getDashboard()).thenThrow(
      const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'Server error',
        statusCode: 500,
      ),
    );

    await expectLater(
      repository.getDashboard(),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
