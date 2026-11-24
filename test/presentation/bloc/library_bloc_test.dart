import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/paginated_result.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_query.dart';
import 'package:lexi_mobile/domain/entities/word_summary.dart';
import 'package:lexi_mobile/domain/usecases/get_words.dart';
import 'package:lexi_mobile/presentation/bloc/library_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/library_event.dart';
import 'package:lexi_mobile/presentation/bloc/library_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWords extends Mock implements GetWords {}

void main() {
  late MockGetWords getWords;

  const summary = WordSummary(
    id: 'word-1',
    word: 'lexicon',
    difficulty: 3,
    aiReady: true,
  );

  PaginatedResult<WordSummary> page({
    List<WordSummary> items = const [summary],
    int number = 1,
    int totalPages = 1,
    int total = 1,
  }) {
    return PaginatedResult(
      items: items,
      page: number,
      limit: 20,
      total: total,
      totalPages: totalPages,
    );
  }

  setUpAll(() {
    registerFallbackValue(const VocabularyQuery());
  });

  setUp(() {
    getWords = MockGetWords();
  });

  blocTest<LibraryBloc, LibraryState>(
    'loads the first page',
    build: () {
      when(() => getWords(any())).thenAnswer((_) async => page());
      return LibraryBloc(getWords);
    },
    act: (bloc) => bloc.add(const LoadLibrary()),
    expect: () => [
      isA<LibraryState>()
          .having((state) => state.isLoading, 'loading', true)
          .having((state) => state.items, 'items', isEmpty),
      isA<LibraryState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.items.single.word, 'word', 'lexicon')
          .having((state) => state.total, 'total', 1),
    ],
  );

  blocTest<LibraryBloc, LibraryState>(
    'emits an empty page for a library with no words',
    build: () {
      when(() => getWords(any())).thenAnswer(
        (_) async => const PaginatedResult<WordSummary>(
          items: [],
          page: 1,
          limit: 20,
          total: 0,
          totalPages: 0,
        ),
      );
      return LibraryBloc(getWords);
    },
    act: (bloc) => bloc.add(const LoadLibrary()),
    expect: () => [
      isA<LibraryState>().having((state) => state.isLoading, 'loading', true),
      isA<LibraryState>()
          .having((state) => state.items, 'items', isEmpty)
          .having((state) => state.isEmpty, 'empty', true),
    ],
  );

  blocTest<LibraryBloc, LibraryState>(
    'applies search, status, and sort to the query',
    build: () {
      when(() => getWords(any())).thenAnswer((_) async => page());
      return LibraryBloc(getWords);
    },
    act: (bloc) async {
      bloc.add(const SearchLibrary('  lex  '));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FilterLibraryByStatus(LearningStatus.learning));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const SortLibrary(VocabularySort.word, VocabularyOrder.ascending),
      );
    },
    skip: 5,
    expect: () => [
      isA<LibraryState>()
          .having((state) => state.query.search, 'search', 'lex')
          .having(
            (state) => state.query.status,
            'status',
            LearningStatus.learning,
          )
          .having((state) => state.query.sort, 'sort', VocabularySort.word)
          .having(
            (state) => state.query.order,
            'order',
            VocabularyOrder.ascending,
          ),
    ],
    verify: (_) {
      final queries = verify(() => getWords(captureAny())).captured
          .cast<VocabularyQuery>();

      expect(queries.first.search, 'lex');
      expect(queries[1].status, LearningStatus.learning);
      expect(queries.last.sort, VocabularySort.word);
    },
  );

  blocTest<LibraryBloc, LibraryState>(
    'appends the next page',
    build: () {
      when(() => getWords(any())).thenAnswer((invocation) {
        final query = invocation.positionalArguments.first as VocabularyQuery;
        if (query.page == 1) {
          return Future.value(page(total: 2, totalPages: 2));
        }
        return Future.value(
          page(
            items: const [
              WordSummary(
                id: 'word-2',
                word: 'syntax',
                difficulty: 2,
                aiReady: false,
              ),
            ],
            number: 2,
            total: 2,
            totalPages: 2,
          ),
        );
      });
      return LibraryBloc(getWords);
    },
    act: (bloc) async {
      bloc.add(const LoadLibrary());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LoadMoreLibrary());
    },
    skip: 3,
    expect: () => [
      isA<LibraryState>()
          .having((state) => state.items.length, 'items', 2)
          .having((state) => state.query.page, 'page', 2)
          .having((state) => state.isLoadingMore, 'loading more', false),
    ],
  );

  blocTest<LibraryBloc, LibraryState>(
    'emits a failure when loading throws',
    build: () {
      when(() => getWords(any())).thenThrow(const NetworkFailure());
      return LibraryBloc(getWords);
    },
    act: (bloc) => bloc.add(const LoadLibrary()),
    expect: () => [
      isA<LibraryState>().having((state) => state.isLoading, 'loading', true),
      isA<LibraryState>()
          .having((state) => state.isLoading, 'loading', false)
          .having((state) => state.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<LibraryBloc, LibraryState>(
    'clears search and status filters',
    build: () {
      when(() => getWords(any())).thenAnswer((_) async => page());
      return LibraryBloc(getWords);
    },
    seed: () => const LibraryState(
      query: VocabularyQuery(search: 'lex', status: LearningStatus.learning),
    ),
    act: (bloc) => bloc.add(const ClearLibraryFilters()),
    skip: 1,
    expect: () => [
      isA<LibraryState>()
          .having((state) => state.query.search, 'search', isNull)
          .having((state) => state.query.status, 'status', isNull),
    ],
  );
}
