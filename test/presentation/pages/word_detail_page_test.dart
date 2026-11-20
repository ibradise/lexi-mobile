import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
import 'package:lexi_mobile/domain/entities/ai_content.dart';
import 'package:lexi_mobile/domain/entities/learning_state.dart';
import 'package:lexi_mobile/domain/entities/review_entry.dart';
import 'package:lexi_mobile/domain/entities/word_detail.dart';
import 'package:lexi_mobile/domain/entities/word_summary.dart';
import 'package:lexi_mobile/domain/usecases/delete_word.dart';
import 'package:lexi_mobile/domain/usecases/get_word_detail.dart';
import 'package:lexi_mobile/domain/usecases/regenerate_word_ai.dart';
import 'package:lexi_mobile/presentation/bloc/word_detail_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/word_detail_event.dart';
import 'package:lexi_mobile/presentation/pages/word_detail_page.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWordDetail extends Mock implements GetWordDetail {}

class MockRegenerateWordAi extends Mock implements RegenerateWordAi {}

class MockDeleteWord extends Mock implements DeleteWord {}

void main() {
  late MockGetWordDetail getWordDetail;
  late MockRegenerateWordAi regenerateWordAi;
  late MockDeleteWord deleteWord;

  const readyDetail = WordDetail(
    summary: WordSummary(
      id: 'word-1',
      word: 'lexicon',
      partOfSpeech: 'noun',
      pronunciation: '/ˈleksɪkɒn/',
      difficulty: 4,
      sourceTitle: 'Example article',
      sourceContext: 'A sentence.',
      sourceUrl: 'https://example.com',
      aiReady: true,
      learningState: LearningState(
        status: LearningStatus.learning,
        knowledgeScore: 0.4,
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 2,
      ),
    ),
    aiModel: 'gemini',
    aiContent: AiContent(
      meanings: [
        WordMeaning(meaning: 'the vocabulary of a language', isPrimary: true),
        WordMeaning(meaning: 'a dictionary', isPrimary: false),
      ],
      examples: [
        WordExample(
          sentence: 'The linguist studied the lexicon.',
          context: 'academic',
        ),
      ],
      synonyms: ['vocabulary'],
      antonyms: [],
      difficulty: 4,
    ),
    reviews: [
      ReviewEntry(
        id: 'review-1',
        exerciseType: 'MULTIPLE_CHOICE',
        result: ReviewResult.correct,
      ),
    ],
  );
  const pendingDetail = WordDetail(
    summary: WordSummary(
      id: 'word-1',
      word: 'lexicon',
      difficulty: 3,
      aiReady: false,
    ),
  );

  WordDetailBloc build({List<Duration>? pollDelays}) {
    return WordDetailBloc(
      getWordDetail,
      regenerateWordAi,
      deleteWord,
      wordId: 'word-1',
      pollDelays: pollDelays ?? const [Duration(hours: 1)],
    );
  }

  setUp(() {
    getWordDetail = MockGetWordDetail();
    regenerateWordAi = MockRegenerateWordAi();
    deleteWord = MockDeleteWord();
  });

  Future<void> pumpDetail(WidgetTester tester, WordDetailBloc bloc) async {
    addTearDown(bloc.close);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<WordDetailBloc>.value(
          value: bloc,
          child: const WordDetailPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders ready AI content and review history', (tester) async {
    when(() => getWordDetail('word-1')).thenAnswer((_) async => readyDetail);
    final bloc = build()..add(const LoadWordDetail());

    await pumpDetail(tester, bloc);

    expect(find.text('lexicon'), findsWidgets);
    expect(find.text('AI ready'), findsOneWidget);
    expect(find.text('the vocabulary of a language'), findsOneWidget);
    expect(find.text('The linguist studied the lexicon.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent reviews'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Example article'), findsOneWidget);
    expect(find.text('Correct · Multiple Choice'), findsOneWidget);
  });

  testWidgets('shows the pending AI panel', (tester) async {
    when(() => getWordDetail('word-1')).thenAnswer((_) async => pendingDetail);
    final bloc = build(pollDelays: const [])..add(const LoadWordDetail());

    await pumpDetail(tester, bloc);

    expect(find.text('AI content is still pending'), findsOneWidget);
    expect(find.byKey(const Key('wordDetailCheckAgainButton')), findsOneWidget);
    expect(find.byKey(const Key('wordDetailRegenerateButton')), findsOneWidget);
  });

  testWidgets('confirms delete and pops back to the library', (tester) async {
    when(() => getWordDetail('word-1')).thenAnswer((_) async => readyDetail);
    when(() => deleteWord('word-1')).thenAnswer((_) async {});
    final bloc = build()..add(const LoadWordDetail());

    await pumpDetail(tester, bloc);

    await tester.tap(find.byKey(const Key('wordDetailMenuButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete word'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this word?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();

    verify(() => deleteWord('word-1')).called(1);
    expect(find.text('home'), findsOneWidget);
  });
}
