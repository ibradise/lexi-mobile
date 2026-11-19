import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/config/app_theme.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/add_word_params.dart';
import 'package:lexi_mobile/domain/entities/added_word.dart';
import 'package:lexi_mobile/domain/entities/bulk_add_result.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_word.dart';
import 'package:lexi_mobile/domain/usecases/add_word.dart';
import 'package:lexi_mobile/domain/usecases/add_words.dart';
import 'package:lexi_mobile/presentation/bloc/add_word_bloc.dart';
import 'package:lexi_mobile/presentation/pages/add_words_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAddWord extends Mock implements AddWord {}

class MockAddWords extends Mock implements AddWords {}

void main() {
  late MockAddWord addWord;
  late MockAddWords addWords;

  setUpAll(() {
    registerFallbackValue(const AddWordParams(word: 'fallback'));
  });

  setUp(() {
    addWord = MockAddWord();
    addWords = MockAddWords();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final bloc = AddWordBloc(addWord, addWords);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<AddWordBloc>.value(
          value: bloc,
          child: const AddWordsPage(),
        ),
      ),
    );
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    final submitButton = find.byKey(const Key('submitButton'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  }

  testWidgets('validates an empty single word', (tester) async {
    await pumpPage(tester);
    await tapSubmit(tester);

    expect(find.text('Enter a word.'), findsOneWidget);
    verifyNever(() => addWord(any()));
  });

  testWidgets('switches to bulk mode and validates empty input', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Bulk paste'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bulkField')), findsOneWidget);

    await tapSubmit(tester);

    expect(find.text('Paste at least one word.'), findsOneWidget);
    verifyNever(() => addWords(any()));
  });

  testWidgets('shows a pending result and resets with add another', (
    tester,
  ) async {
    when(() => addWord(any())).thenAnswer(
      (_) async =>
          const VocabularyWord(id: 'word-1', word: 'lexicon', aiReady: false),
    );

    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('wordField')), 'lexicon');
    await tapSubmit(tester);

    expect(find.text('Word added'), findsOneWidget);
    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('AI content is being generated.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addAnotherButton')));
    await tester.pumpAndSettle();

    final wordField = tester.widget<TextFormField>(
      find.byKey(const Key('wordField')),
    );
    expect(wordField.controller?.text, isEmpty);
  });

  testWidgets('shows a duplicate error with retry', (tester) async {
    when(() => addWord(any()))
        .thenThrow(const DuplicateWordFailure(existingWordId: 'word-1'));

    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('wordField')), 'lexicon');
    await tapSubmit(tester);

    expect(find.text('This word already exists.'), findsOneWidget);
    expect(find.byKey(const Key('retryButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retryButton')));
    await tester.pumpAndSettle();

    verify(() => addWord(any())).called(2);
  });

  testWidgets('shows the bulk summary', (tester) async {
    when(() => addWords('lexicon syntax')).thenAnswer(
      (_) async => const BulkAddResult(
        added: [
          AddedWord(id: 'word-1', word: 'lexicon'),
          AddedWord(id: 'word-2', word: 'syntax'),
        ],
        duplicates: ['oldword'],
        invalid: ['too-long'],
      ),
    );

    await pumpPage(tester);

    await tester.tap(find.text('Bulk paste'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bulkField')),
      'lexicon syntax',
    );
    await tapSubmit(tester);

    expect(find.text('Words added'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Duplicates'), findsOneWidget);
    expect(find.text('Invalid'), findsOneWidget);
    expect(find.text('lexicon'), findsOneWidget);
    expect(find.text('syntax'), findsOneWidget);
    expect(find.text('Duplicates: oldword'), findsOneWidget);
    expect(find.text('Invalid: too-long'), findsOneWidget);
  });
}
