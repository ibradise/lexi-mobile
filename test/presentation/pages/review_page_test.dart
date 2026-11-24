import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_queue.dart';
import 'package:lexi_mobile/domain/usecases/get_today_review.dart';
import 'package:lexi_mobile/presentation/bloc/review_queue_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/review_queue_event.dart';
import 'package:lexi_mobile/presentation/navigation/app_routes.dart';
import 'package:lexi_mobile/presentation/pages/review_page.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTodayReview extends Mock implements GetTodayReview {}

void main() {
  late MockGetTodayReview getTodayReview;

  const queue = ReviewQueue(
    totalDue: 2,
    newWords: 1,
    reviewWords: 1,
    queue: [
      ReviewQueueItem(
        wordId: 'word-1',
        word: 'lexicon',
        priority: 0.9,
        knowledgeScore: 0.2,
        status: LearningStatus.learning,
        aiReady: true,
      ),
      ReviewQueueItem(
        wordId: 'word-2',
        word: 'syntax',
        priority: 0.5,
        knowledgeScore: 0,
        status: LearningStatus.newWord,
        aiReady: false,
      ),
    ],
  );

  setUp(() {
    getTodayReview = MockGetTodayReview();
  });

  Future<void> pumpReview(WidgetTester tester, ReviewQueueBloc bloc) async {
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<ReviewQueueBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ReviewPage(),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.reviewSession) {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: Text('review session page')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows today counts, queue, and pending AI notice', (
    tester,
  ) async {
    when(() => getTodayReview()).thenAnswer((_) async => queue);
    final bloc = ReviewQueueBloc(getTodayReview)..add(const LoadReviewQueue());

    await pumpReview(tester, bloc);

    expect(find.text("Today's review"), findsOneWidget);
    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('syntax'), findsOneWidget);
    expect(find.text('AI pending'), findsOneWidget);
    expect(find.textContaining('waiting for AI content'), findsOneWidget);
    expect(find.byKey(const Key('reviewStartButton')), findsOneWidget);
  });

  testWidgets('starts the review session', (tester) async {
    when(() => getTodayReview()).thenAnswer((_) async => queue);
    final bloc = ReviewQueueBloc(getTodayReview)..add(const LoadReviewQueue());

    await pumpReview(tester, bloc);

    await tester.tap(find.byKey(const Key('reviewStartButton')));
    await tester.pumpAndSettle();

    expect(find.text('review session page'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    when(() => getTodayReview()).thenAnswer(
      (_) async => const ReviewQueue(
        totalDue: 0,
        newWords: 0,
        reviewWords: 0,
        queue: [],
      ),
    );
    final bloc = ReviewQueueBloc(getTodayReview)..add(const LoadReviewQueue());

    await pumpReview(tester, bloc);

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('shows an error and retries', (tester) async {
    var attempts = 0;
    when(() => getTodayReview()).thenAnswer((_) async {
      if (attempts++ == 0) {
        throw const NetworkFailure();
      }
      return queue;
    });
    final bloc = ReviewQueueBloc(getTodayReview)..add(const LoadReviewQueue());

    await pumpReview(tester, bloc);

    expect(
      find.text('Cannot reach Lexi. Check your connection and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reviewRetryButton')));
    await tester.pumpAndSettle();

    expect(find.text("Today's review"), findsOneWidget);
  });
}
