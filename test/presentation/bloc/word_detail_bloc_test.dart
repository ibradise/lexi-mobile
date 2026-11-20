import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/domain/entities/word_detail.dart';
import 'package:lexi_mobile/domain/entities/word_summary.dart';
import 'package:lexi_mobile/domain/usecases/delete_word.dart';
import 'package:lexi_mobile/domain/usecases/get_word_detail.dart';
import 'package:lexi_mobile/domain/usecases/regenerate_word_ai.dart';
import 'package:lexi_mobile/presentation/bloc/word_detail_bloc.dart';
import 'package:lexi_mobile/presentation/bloc/word_detail_event.dart';
import 'package:lexi_mobile/presentation/bloc/word_detail_state.dart';
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
      difficulty: 3,
      aiReady: true,
    ),
    aiModel: 'gemini',
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
      pollDelays: pollDelays,
    );
  }

  setUp(() {
    getWordDetail = MockGetWordDetail();
    regenerateWordAi = MockRegenerateWordAi();
    deleteWord = MockDeleteWord();
  });

  blocTest<WordDetailBloc, WordDetailState>(
    'loads ready detail',
    build: () {
      when(() => getWordDetail('word-1')).thenAnswer((_) async => readyDetail);
      return build(pollDelays: const [Duration(hours: 1)]);
    },
    act: (bloc) => bloc.add(const LoadWordDetail()),
    skip: 1,
    expect: () => [
      isA<WordDetailState>()
          .having((state) => state.status, 'status', WordDetailStatus.ready)
          .having((state) => state.detail?.summary.word, 'word', 'lexicon'),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'polls pending AI until it becomes ready',
    build: () {
      var calls = 0;
      when(() => getWordDetail('word-1')).thenAnswer((_) async {
        calls += 1;
        return calls == 1 ? pendingDetail : readyDetail;
      });
      return build(pollDelays: const [Duration.zero]);
    },
    act: (bloc) => bloc.add(const LoadWordDetail()),
    skip: 1,
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.status,
        'pending',
        WordDetailStatus.pending,
      ),
      isA<WordDetailState>()
          .having((state) => state.status, 'status', WordDetailStatus.ready)
          .having((state) => state.pollExhausted, 'exhausted', false),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'marks polling exhausted after the retry schedule',
    build: () {
      when(() => getWordDetail('word-1'))
          .thenAnswer((_) async => pendingDetail);
      return build(pollDelays: const [Duration.zero]);
    },
    act: (bloc) => bloc.add(const LoadWordDetail()),
    skip: 1,
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.status,
        'pending',
        WordDetailStatus.pending,
      ),
      isA<WordDetailState>().having(
        (state) => state.pollExhausted,
        'exhausted',
        true,
      ),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'regenerates AI content',
    build: () {
      when(() => regenerateWordAi('word-1'))
          .thenAnswer((_) async => readyDetail);
      return build(pollDelays: const [Duration(hours: 1)]);
    },
    seed: () => const WordDetailState(
      wordId: 'word-1',
      status: WordDetailStatus.ready,
      detail: readyDetail,
    ),
    act: (bloc) => bloc.add(const RegenerateWordDetailAi()),
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.isRegenerating,
        'regenerating',
        true,
      ),
      isA<WordDetailState>()
          .having((state) => state.isRegenerating, 'regenerating', false)
          .having((state) => state.status, 'status', WordDetailStatus.ready),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'soft-deletes the word',
    build: () {
      when(() => deleteWord('word-1')).thenAnswer((_) async {});
      return build(pollDelays: const [Duration(hours: 1)]);
    },
    seed: () => const WordDetailState(
      wordId: 'word-1',
      status: WordDetailStatus.ready,
      detail: readyDetail,
    ),
    act: (bloc) => bloc.add(const DeleteWordDetail()),
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.isDeleting,
        'deleting',
        true,
      ),
      isA<WordDetailState>()
          .having((state) => state.isDeleting, 'deleting', false)
          .having((state) => state.status, 'status', WordDetailStatus.deleted),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'reports a missing word when delete returns 404',
    build: () {
      when(() => deleteWord('word-1')).thenThrow(const NotFoundFailure());
      return build(pollDelays: const [Duration(hours: 1)]);
    },
    seed: () => const WordDetailState(
      wordId: 'word-1',
      status: WordDetailStatus.ready,
      detail: readyDetail,
    ),
    act: (bloc) => bloc.add(const DeleteWordDetail()),
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.isDeleting,
        'deleting',
        true,
      ),
      isA<WordDetailState>().having(
        (state) => state.status,
        'status',
        WordDetailStatus.notFound,
      ),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'emits not-found when the word is missing',
    build: () {
      when(() => getWordDetail('word-1')).thenThrow(const NotFoundFailure());
      return build(pollDelays: const [Duration(hours: 1)]);
    },
    act: (bloc) => bloc.add(const LoadWordDetail()),
    skip: 1,
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.status,
        'status',
        WordDetailStatus.notFound,
      ),
    ],
  );

  blocTest<WordDetailBloc, WordDetailState>(
    'keeps the current detail when regenerate fails',
    build: () {
      when(() => regenerateWordAi('word-1')).thenThrow(const NetworkFailure());
      return build(pollDelays: const [Duration(hours: 1)]);
    },
    seed: () => const WordDetailState(
      wordId: 'word-1',
      status: WordDetailStatus.ready,
      detail: readyDetail,
    ),
    act: (bloc) => bloc.add(const RegenerateWordDetailAi()),
    expect: () => [
      isA<WordDetailState>().having(
        (state) => state.isRegenerating,
        'regenerating',
        true,
      ),
      isA<WordDetailState>()
          .having((state) => state.isRegenerating, 'regenerating', false)
          .having(
            (state) => state.actionFailure,
            'failure',
            isA<NetworkFailure>(),
          )
          .having((state) => state.status, 'status', WordDetailStatus.ready),
    ],
  );

  test('cancels a scheduled poll when closed', () async {
    when(() => getWordDetail('word-1')).thenAnswer((_) async => pendingDetail);
    final bloc = build(pollDelays: const [Duration(milliseconds: 30)]);

    bloc.add(const LoadWordDetail());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await bloc.close();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    verify(() => getWordDetail('word-1')).called(1);
  });
}
