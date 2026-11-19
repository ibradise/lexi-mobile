import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/add_word_params.dart';
import 'package:lexi_mobile/domain/entities/added_word.dart';
import 'package:lexi_mobile/domain/entities/bulk_add_result.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_word.dart';
import 'package:lexi_mobile/domain/usecases/add_word.dart';
import 'package:lexi_mobile/domain/usecases/add_words.dart';
import 'package:lexi_mobile/presentation/bloc/add_word_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/add_word_event.dart';
import 'package:lexi_mobile/presentation/bloc/add_word_state.dart';
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

  blocTest<AddWordBloc, AddWordState>(
    'emits submitting then a ready single-word success',
    setUp: () {
      when(() => addWord(any())).thenAnswer(
        (_) async =>
            const VocabularyWord(id: 'word-1', word: 'lexicon', aiReady: true),
      );
    },
    build: () => AddWordBloc(addWord, addWords),
    act: (bloc) {
      bloc.add(const SubmitSingleWord(AddWordParams(word: 'lexicon')));
    },
    expect: () => [
      const AddWordSubmitting(isBulk: false),
      isA<AddWordSingleSuccess>().having(
        (state) => state.word.aiReady,
        'aiReady',
        isTrue,
      ),
    ],
    verify: (_) {
      verify(() => addWord(any())).called(1);
    },
  );

  blocTest<AddWordBloc, AddWordState>(
    'emits a pending single-word success',
    setUp: () {
      when(() => addWord(any())).thenAnswer(
        (_) async =>
            const VocabularyWord(id: 'word-1', word: 'lexicon', aiReady: false),
      );
    },
    build: () => AddWordBloc(addWord, addWords),
    act: (bloc) {
      bloc.add(const SubmitSingleWord(AddWordParams(word: 'lexicon')));
    },
    expect: () => [
      const AddWordSubmitting(isBulk: false),
      isA<AddWordSingleSuccess>().having(
        (state) => state.word.aiReady,
        'aiReady',
        isFalse,
      ),
    ],
  );

  blocTest<AddWordBloc, AddWordState>(
    'emits a duplicate failure',
    setUp: () {
      when(() => addWord(any()))
          .thenThrow(const DuplicateWordFailure(existingWordId: 'word-1'));
    },
    build: () => AddWordBloc(addWord, addWords),
    act: (bloc) {
      bloc.add(const SubmitSingleWord(AddWordParams(word: 'lexicon')));
    },
    expect: () => [
      const AddWordSubmitting(isBulk: false),
      isA<AddWordFailure>()
          .having(
            (state) => state.failure,
            'failure',
            isA<DuplicateWordFailure>(),
          )
          .having((state) => state.isBulk, 'isBulk', isFalse),
    ],
  );

  blocTest<AddWordBloc, AddWordState>(
    'emits submitting then a bulk success',
    setUp: () {
      when(() => addWords('lexicon syntax')).thenAnswer(
        (_) async => const BulkAddResult(
          added: [
            AddedWord(id: 'word-1', word: 'lexicon'),
            AddedWord(id: 'word-2', word: 'syntax'),
          ],
          duplicates: ['oldword'],
          invalid: [],
        ),
      );
    },
    build: () => AddWordBloc(addWord, addWords),
    act: (bloc) {
      bloc.add(const SubmitBulkWords('lexicon syntax'));
    },
    expect: () => [
      const AddWordSubmitting(isBulk: true),
      isA<AddWordBulkSuccess>().having(
        (state) => state.result.added.length,
        'added count',
        2,
      ),
    ],
    verify: (_) {
      verify(() => addWords('lexicon syntax')).called(1);
    },
  );

  blocTest<AddWordBloc, AddWordState>(
    'emits a network failure for a bulk request',
    setUp: () {
      when(() => addWords('lexicon')).thenThrow(const NetworkFailure());
    },
    build: () => AddWordBloc(addWord, addWords),
    act: (bloc) {
      bloc.add(const SubmitBulkWords('lexicon'));
    },
    expect: () => [
      const AddWordSubmitting(isBulk: true),
      isA<AddWordFailure>()
          .having((state) => state.failure, 'failure', isA<NetworkFailure>())
          .having((state) => state.isBulk, 'isBulk', isTrue),
    ],
  );
}
