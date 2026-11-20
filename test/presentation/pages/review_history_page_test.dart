import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/paginated_result.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/review_history_item.dart';
import 'package:lexi_mobile/domain/entities/review_history_query.dart';
import 'package:lexi_mobile/domain/usecases/get_review_history.dart';
import 'package:lexi_mobile/presentation/bloc/review_history_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/review_history_event.dart';
import 'package:lexi_mobile/presentation/navigation/app_routes.dart';
import 'package:lexi_mobile/presentation/pages/review_history_page.dart';
import 'package:mocktail/mocktail.dart';

class MockGetReviewHistory extends Mock implements GetReviewHistory {}

void main() {
  late MockGetReviewHistory getReviewHistory;

  final page = PaginatedResult<ReviewHistoryItem>(
    items: [
      ReviewHistoryItem(
        id: 'review-1',
        wordId: 'word-1',
        word: 'lexicon',
        exerciseType: 'MULTIPLE_CHOICE',
        result: ReviewResult.correct,
        responseTimeMs: 2300,
        hintUsed: true,
        createdAt: DateTime.utc(2026, 11, 14, 9, 20),
      ),
    ],
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
  );

  setUpAll(() {
    registerFallbackValue(const ReviewHistoryQuery());
  });

  setUp(() {
    getReviewHistory = MockGetReviewHistory();
  });

  Future<void> pumpHistory(WidgetTester tester, ReviewHistoryBloc bloc) async {
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<ReviewHistoryBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReviewHistoryPage(),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.wordDetail) {
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('word detail page')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows review history items and opens the word', (tester) async {
    when(() => getReviewHistory(const ReviewHistoryQuery()))
        .thenAnswer((_) async => page);
    final bloc = ReviewHistoryBloc(getReviewHistory)
      ..add(const LoadReviewHistory());

    await pumpHistory(tester, bloc);

    expect(find.text('Review history'), findsOneWidget);
    expect(find.text('1 review'), findsOneWidget);
    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.textContaining('2.3s'), findsOneWidget);
    expect(find.textContaining('Hint used'), findsOneWidget);

    await tester.tap(find.byKey(const Key('historyItem-review-1')));
    await tester.pumpAndSettle();

    expect(find.text('word detail page'), findsOneWidget);
  });

  testWidgets('shows the empty history state', (tester) async {
    when(() => getReviewHistory(const ReviewHistoryQuery())).thenAnswer(
      (_) async => const PaginatedResult(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0,
      ),
    );
    final bloc = ReviewHistoryBloc(getReviewHistory)
      ..add(const LoadReviewHistory());

    await pumpHistory(tester, bloc);

    expect(find.text('No reviews yet'), findsOneWidget);
  });

  testWidgets('shows an error and retries', (tester) async {
    var attempts = 0;
    when(() => getReviewHistory(const ReviewHistoryQuery()))
        .thenAnswer((_) async {
          if (attempts++ == 0) {
            throw const NetworkFailure();
          }
          return page;
        });
    final bloc = ReviewHistoryBloc(getReviewHistory)
      ..add(const LoadReviewHistory());

    await pumpHistory(tester, bloc);

    expect(
      find.text('Cannot reach Lexi. Check your connection and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('historyRetryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Review history'), findsOneWidget);
  });
}
