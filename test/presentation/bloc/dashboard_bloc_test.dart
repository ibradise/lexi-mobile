import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/dashboard_data.dart';
import 'package:lexi_mobile/domain/usecases/get_dashboard.dart';
import 'package:lexi_mobile/presentation/bloc/dashboard_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/dashboard_event.dart';
import 'package:lexi_mobile/presentation/bloc/dashboard_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDashboard extends Mock implements GetDashboard {}

void main() {
  late MockGetDashboard getDashboard;

  const data = DashboardData(
    todayReview: DashboardTodayReview(
      due: 1,
      newWords: 1,
      needAttention: 0,
      becomingStrong: 0,
    ),
    weakestWords: [],
    stats: DashboardStats(
      totalWords: 1,
      newWords: 1,
      learning: 0,
      familiar: 0,
      strong: 0,
      mastered: 0,
      reviewsToday: 0,
      accuracyLast7Days: 0,
      currentStreak: 0,
    ),
  );

  setUp(() {
    getDashboard = MockGetDashboard();
  });

  blocTest<DashboardBloc, DashboardState>(
    'loads dashboard data',
    build: () {
      when(() => getDashboard()).thenAnswer((_) async => data);
      return DashboardBloc(getDashboard);
    },
    act: (bloc) => bloc.add(const LoadDashboard()),
    expect: () => [
      isA<DashboardState>().having((state) => state.isLoading, 'loading', true),
      isA<DashboardState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.data?.todayReview.due, 'due', 1),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'emits a failure when the dashboard cannot load',
    build: () {
      when(() => getDashboard()).thenThrow(const NetworkFailure());
      return DashboardBloc(getDashboard);
    },
    act: (bloc) => bloc.add(const LoadDashboard()),
    expect: () => [
      isA<DashboardState>().having((state) => state.isLoading, 'loading', true),
      isA<DashboardState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
