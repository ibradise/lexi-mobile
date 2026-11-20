import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/paginated_result.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_query.dart';
import 'package:lexi_mobile/domain/entities/word_summary.dart';
import 'package:lexi_mobile/domain/usecases/get_words.dart';
import 'package:lexi_mobile/presentation/bloc/library_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/library_event.dart';
import 'package:lexi_mobile/presentation/navigation/app_routes.dart';
import 'package:lexi_mobile/presentation/pages/library_page.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWords extends Mock implements GetWords {}

void main() {
  late MockGetWords getWords;

  const summary = WordSummary(
    id: 'word-1',
    word: 'lexicon',
    partOfSpeech: 'noun',
    pronunciation: '/ˈleksɪkɒn/',
    difficulty: 3,
    aiReady: true,
    learningState: LearningState(
      status: LearningStatus.learning,
      knowledgeScore: 0.4,
      easeFactor: 2.5,
      intervalDays: 1,
      repetitions: 1,
    ),
  );

  setUpAll(() {
    registerFallbackValue(const VocabularyQuery());
  });

  setUp(() {
    getWords = MockGetWords();
  });

  Future<void> pumpLibrary(WidgetTester tester, LibraryBloc bloc) async {
    await tester.pumpWidget(
      BlocProvider<LibraryBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LibraryPage(),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.wordDetail) {
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('detail page')),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state and add CTA', (tester) async {
    when(() => getWords(any())).thenAnswer(
      (_) async => const PaginatedResult<WordSummary>(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0,
      ),
    );
    final bloc = LibraryBloc(getWords)..add(const LoadLibrary());

    await pumpLibrary(tester, bloc);

    expect(find.text('No words yet'), findsOneWidget);
    expect(find.byKey(const Key('libraryAddWordsButton')), findsOneWidget);
  });

  testWidgets('renders a word card and opens detail', (tester) async {
    when(() => getWords(any())).thenAnswer(
      (_) async => const PaginatedResult<WordSummary>(
        items: [summary],
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      ),
    );
    final bloc = LibraryBloc(getWords)..add(const LoadLibrary());

    await pumpLibrary(tester, bloc);

    expect(find.text('Showing 1 of 1 words'), findsOneWidget);
    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('Learning'), findsWidgets);
    expect(find.text('AI ready'), findsOneWidget);

    await tester.tap(find.byKey(const Key('libraryWord-word-1')));
    await tester.pumpAndSettle();

    expect(find.text('detail page'), findsOneWidget);
  });

  testWidgets('submits search and filters by status', (tester) async {
    when(() => getWords(any())).thenAnswer(
      (_) async => const PaginatedResult<WordSummary>(
        items: [summary],
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      ),
    );
    final bloc = LibraryBloc(getWords)..add(const LoadLibrary());

    await pumpLibrary(tester, bloc);

    await tester.enterText(find.byKey(const Key('librarySearchField')), 'lex');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('libraryStatus-LEARNING')));
    await tester.pumpAndSettle();

    final queries = verify(() => getWords(captureAny())).captured
        .cast<VocabularyQuery>();

    expect(queries.any((query) => query.search == 'lex'), isTrue);
    expect(queries.last.status, LearningStatus.learning);
  });
}
