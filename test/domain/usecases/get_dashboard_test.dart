import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/domain/entities/dashboard_data.dart';
import 'package:lexi_mobile/domain/repositories/dashboard_repository.dart';
import 'package:lexi_mobile/domain/usecases/get_dashboard.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository repository;

  const data = DashboardData(
    todayReview: DashboardTodayReview(
      due: 2,
      newWords: 1,
      needAttention: 0,
      becomingStrong: 1,
    ),
    weakestWords: [],
    stats: DashboardStats(
      totalWords: 4,
      newWords: 1,
      learning: 1,
      familiar: 1,
      strong: 1,
      mastered: 0,
      reviewsToday: 2,
      accuracyLast7Days: 0.5,
      currentStreak: 1,
    ),
  );

  setUp(() {
    repository = MockDashboardRepository();
  });

  test('delegates to the repository', () async {
    when(() => repository.getDashboard()).thenAnswer((_) async => data);

    final result = await GetDashboard(repository)();

    expect(result.todayReview.due, 2);
    verify(() => repository.getDashboard()).called(1);
  });
}
