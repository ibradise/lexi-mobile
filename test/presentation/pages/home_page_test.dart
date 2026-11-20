import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/dashboard_data.dart';
import 'package:lexi_mobile/domain/usecases/get_dashboard.dart';
import 'package:lexi_mobile/presentation/bloc/dashboard_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/dashboard_event.dart';
import 'package:lexi_mobile/presentation/pages/home_page.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDashboard extends Mock implements GetDashboard {}

void main() {
  late MockGetDashboard getDashboard;
  var addCalls = 0;
  var startCalls = 0;
  WeakestWord? openedWord;

  const populated = DashboardData(
    todayReview: DashboardTodayReview(
      due: 5,
      newWords: 2,
      needAttention: 1,
      becomingStrong: 2,
    ),
    weakestWords: [
      WeakestWord(wordId: 'word-1', word: 'lexicon', knowledgeScore: 0.15),
      WeakestWord(wordId: 'word-2', word: 'syntax', knowledgeScore: 0.25),
    ],
    stats: DashboardStats(
      totalWords: 12,
      newWords: 3,
      learning: 4,
      familiar: 2,
      strong: 2,
      mastered: 1,
      reviewsToday: 4,
      accuracyLast7Days: 0.75,
      currentStreak: 2,
    ),
  );

  const empty = DashboardData(
    todayReview: DashboardTodayReview(
      due: 0,
      newWords: 0,
      needAttention: 0,
      becomingStrong: 0,
    ),
    weakestWords: [],
    stats: DashboardStats(
      totalWords: 0,
      newWords: 0,
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
    addCalls = 0;
    startCalls = 0;
    openedWord = null;
  });

  Future<void> pumpDashboard(WidgetTester tester, DashboardBloc bloc) async {
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<DashboardBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: HomePage(
            onAddWords: () => addCalls++,
            onStartReview: () => startCalls++,
            onOpenWord: (word) => openedWord = word,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows today counts, progress, and weakest words', (
    tester,
  ) async {
    when(() => getDashboard()).thenAnswer((_) async => populated);
    final bloc = DashboardBloc(getDashboard)..add(const LoadDashboard());

    await pumpDashboard(tester, bloc);

    expect(find.text("Today's review"), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.byKey(const Key('dashboardStartButton')), findsOneWidget);

    await tester.scrollUntilVisible(find.text('lexicon'), 300);

    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('Knowledge score 15%'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('syntax'), 300);

    expect(find.text('syntax'), findsOneWidget);
  });

  testWidgets('starts a review from the dashboard', (tester) async {
    when(() => getDashboard()).thenAnswer((_) async => populated);
    final bloc = DashboardBloc(getDashboard)..add(const LoadDashboard());

    await pumpDashboard(tester, bloc);

    await tester.tap(find.byKey(const Key('dashboardStartButton')));

    expect(startCalls, 1);
    expect(find.text('Review session'), findsNothing);
  });

  testWidgets('opens a weakest word', (tester) async {
    when(() => getDashboard()).thenAnswer((_) async => populated);
    final bloc = DashboardBloc(getDashboard)..add(const LoadDashboard());

    await pumpDashboard(tester, bloc);
    await tester.scrollUntilVisible(
      find.byKey(const Key('dashboardWeakest-word-1')),
      300,
    );

    await tester.tap(find.byKey(const Key('dashboardWeakest-word-1')));

    expect(openedWord?.wordId, 'word-1');
  });

  testWidgets('shows the empty-library call to action', (tester) async {
    when(() => getDashboard()).thenAnswer((_) async => empty);
    final bloc = DashboardBloc(getDashboard)..add(const LoadDashboard());

    await pumpDashboard(tester, bloc);

    expect(find.text('No words yet'), findsOneWidget);
    expect(find.byKey(const Key('dashboardEmptyAddButton')), findsOneWidget);
    expect(find.byKey(const Key('dashboardStartButton')), findsNothing);

    await tester.tap(find.byKey(const Key('dashboardEmptyAddButton')));

    expect(addCalls, 1);
  });

  testWidgets('shows an error and retries', (tester) async {
    var attempts = 0;
    when(() => getDashboard()).thenAnswer((_) async {
      if (attempts++ == 0) {
        throw const NetworkFailure();
      }
      return populated;
    });
    final bloc = DashboardBloc(getDashboard)..add(const LoadDashboard());

    await pumpDashboard(tester, bloc);

    expect(
      find.text('Cannot reach Lexi. Check your connection and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('dashboardRetryButton')));
    await tester.pumpAndSettle();

    expect(find.text("Today's review"), findsOneWidget);
  });
}
