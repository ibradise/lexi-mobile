import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/core/error/app_failure.dart';
import 'package:lexi_mobile/core/network/api_exception.dart';
import 'package:lexi_mobile/data/datasources/vocabulary_remote_data_source.dart';
import 'package:lexi_mobile/data/models/added_word_model.dart';
import 'package:lexi_mobile/data/models/bulk_add_result_model.dart';
import 'package:lexi_mobile/data/models/vocabulary_word_model.dart';
import 'package:lexi_mobile/data/repositories/vocabulary_repository_impl.dart';
import 'package:lexi_mobile/domain/entities/add_word_params.dart';
import 'package:mocktail/mocktail.dart';

class MockVocabularyRemoteDataSource extends Mock
    implements VocabularyRemoteDataSource {}

void main() {
  late MockVocabularyRemoteDataSource remoteDataSource;
  late VocabularyRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockVocabularyRemoteDataSource();
    repository = VocabularyRepositoryImpl(remoteDataSource);
  });

  test('maps a single-word model to a domain entity', () async {
    when(
      () => remoteDataSource.addWord(
        word: 'lexicon',
        context: 'A sentence.',
        sourceTitle: 'Example article',
        sourceUrl: 'https://example.com/article',
      ),
    ).thenAnswer(
      (_) async => const VocabularyWordModel(
        id: 'word-1',
        word: 'lexicon',
        aiReady: true,
      ),
    );

    final result = await repository.addWord(
      const AddWordParams(
        word: 'lexicon',
        context: 'A sentence.',
        sourceTitle: 'Example article',
        sourceUrl: 'https://example.com/article',
      ),
    );

    expect(result.id, 'word-1');
    expect(result.word, 'lexicon');
    expect(result.aiReady, isTrue);
  });

  test('maps a bulk result model to domain entities', () async {
    when(() => remoteDataSource.addWords(['lexicon, syntax'])).thenAnswer(
      (_) async => const BulkAddResultModel(
        added: [AddedWordModel(id: 'word-1', word: 'lexicon')],
        duplicates: ['syntax'],
        invalid: ['too-long'],
      ),
    );

    final result = await repository.addWords(['lexicon, syntax']);

    expect(result.added.single.id, 'word-1');
    expect(result.added.single.word, 'lexicon');
    expect(result.duplicates, ['syntax']);
    expect(result.invalid, ['too-long']);
  });

  test('translates duplicate-word errors into a domain failure', () async {
    when(
      () => remoteDataSource.addWord(
        word: 'lexicon',
        context: null,
        sourceTitle: null,
        sourceUrl: null,
      ),
    ).thenThrow(
      const ApiException(
        code: 'DUPLICATE_WORD',
        message: 'Word already exists',
        statusCode: 409,
        details: {'id': 'word-1'},
      ),
    );

    await expectLater(
      repository.addWord(const AddWordParams(word: 'lexicon')),
      throwsA(
        isA<DuplicateWordFailure>()
            .having(
              (failure) => failure.existingWordId,
              'existing id',
              'word-1',
            )
            .having(
              (failure) => failure.message,
              'message',
              'Word already exists',
            ),
      ),
    );
  });

  test('translates unexpected errors into an unknown failure', () async {
    when(() => remoteDataSource.addWords(['lexicon']))
        .thenThrow(StateError('boom'));

    await expectLater(
      repository.addWords(['lexicon']),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
