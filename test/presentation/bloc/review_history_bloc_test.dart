import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/paginated_result.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/review_history_item.dart';
import 'package:lexi_mobile/domain/entities/review_history_query.dart';
import 'package:lexi_mobile/domain/usecases/get_review_history.dart';
import 'package:lexi_mobile/presentation/bloc/review_history_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/review_history_event.dart';
import 'package:lexi_mobile/presentation/bloc/review_history_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetReviewHistory extends Mock implements GetReviewHistory {}

void main() {
  late MockGetReviewHistory getReviewHistory;

  const firstPage = PaginatedResult<ReviewHistoryItem>(
    items: [
      ReviewHistoryItem(
        id: 'review-1',
        wordId: 'word-1',
        word: 'lexicon',
        exerciseType: 'MULTIPLE_CHOICE',
        result: ReviewResult.correct,
      ),
    ],
    page: 1,
    limit: 20,
    total: 2,
    totalPages: 2,
  );
  const secondPage = PaginatedResult<ReviewHistoryItem>(
    items: [
      ReviewHistoryItem(
        id: 'review-2',
        wordId: 'word-2',
        word: 'syntax',
        exerciseType: 'MULTIPLE_CHOICE',
        result: ReviewResult.incorrect,
      ),
    ],
    page: 2,
    limit: 20,
    total: 2,
    totalPages: 2,
  );

  setUpAll(() {
    registerFallbackValue(const ReviewHistoryQuery());
  });

  setUp(() {
    getReviewHistory = MockGetReviewHistory();
  });

  blocTest<ReviewHistoryBloc, ReviewHistoryState>(
    'loads the first page',
    build: () {
      when(() => getReviewHistory(const ReviewHistoryQuery()))
          .thenAnswer((_) async => firstPage);
      return ReviewHistoryBloc(getReviewHistory);
    },
    act: (bloc) => bloc.add(const LoadReviewHistory()),
    expect: () => [
      isA<ReviewHistoryState>().having(
        (state) => state.isLoading,
        'loading',
        true,
      ),
      isA<ReviewHistoryState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.items.single.word, 'word', 'lexicon')
          .having((state) => state.hasMore, 'has more', isTrue),
    ],
  );

  blocTest<ReviewHistoryBloc, ReviewHistoryState>(
    'appends the next page',
    build: () {
      when(() => getReviewHistory(const ReviewHistoryQuery()))
          .thenAnswer((_) async => firstPage);
      when(() => getReviewHistory(const ReviewHistoryQuery(page: 2)))
          .thenAnswer((_) async => secondPage);
      return ReviewHistoryBloc(getReviewHistory);
    },
    act: (bloc) async {
      bloc.add(const LoadReviewHistory());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LoadMoreReviewHistory());
    },
    skip: 2,
    expect: () => [
      isA<ReviewHistoryState>().having(
        (state) => state.isLoadingMore,
        'loading more',
        true,
      ),
      isA<ReviewHistoryState>()
          .having((state) => state.items, 'items', hasLength(2))
          .having((state) => state.items.last.word, 'last word', 'syntax')
          .having((state) => state.hasMore, 'has more', isFalse),
    ],
  );

  blocTest<ReviewHistoryBloc, ReviewHistoryState>(
    'filters by word and clears it',
    build: () {
      when(() => getReviewHistory(const ReviewHistoryQuery()))
          .thenAnswer((_) async => firstPage);
      when(() => getReviewHistory(const ReviewHistoryQuery(wordId: 'word-1')))
          .thenAnswer((_) async => firstPage);
      return ReviewHistoryBloc(getReviewHistory);
    },
    act: (bloc) async {
      bloc.add(const FilterReviewHistoryByWord(' word-1 '));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FilterReviewHistoryByWord(null));
    },
    skip: 3,
    expect: () => [
      isA<ReviewHistoryState>()
          .having((state) => state.query.wordId, 'filter', isNull)
          .having((state) => state.isLoading, 'loading', false),
    ],
  );

  blocTest<ReviewHistoryBloc, ReviewHistoryState>(
    'emits a failure when the first page cannot load',
    build: () {
      when(() => getReviewHistory(any())).thenThrow(const NetworkFailure());
      return ReviewHistoryBloc(getReviewHistory);
    },
    act: (bloc) => bloc.add(const LoadReviewHistory()),
    expect: () => [
      isA<ReviewHistoryState>().having(
        (state) => state.isLoading,
        'loading',
        true,
      ),
      isA<ReviewHistoryState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
