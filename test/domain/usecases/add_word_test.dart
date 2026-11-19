import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/domain/entities/add_word_params.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_word.dart';
import 'package:lexi_mobile/domain/repositories/vocabulary_repository.dart';
import 'package:lexi_mobile/domain/usecases/add_word.dart';
import 'package:mocktail/mocktail.dart';

class MockVocabularyRepository extends Mock implements VocabularyRepository {}

void main() {
  late MockVocabularyRepository repository;

  setUpAll(() {
    registerFallbackValue(const AddWordParams(word: 'fallback'));
  });

  setUp(() {
    repository = MockVocabularyRepository();
  });

  test('trims the word and normalizes optional fields', () async {
    when(() => repository.addWord(any())).thenAnswer(
      (_) async =>
          const VocabularyWord(id: 'word-1', word: 'lexicon', aiReady: true),
    );

    final result = await AddWord(repository)(
      const AddWordParams(
        word: '  lexicon  ',
        context: '  A sentence.  ',
        sourceTitle: '   ',
        sourceUrl: ' https://example.com ',
      ),
    );

    final params =
        verify(() => repository.addWord(captureAny())).captured.single
            as AddWordParams;

    expect(params.word, 'lexicon');
    expect(params.context, 'A sentence.');
    expect(params.sourceTitle, isNull);
    expect(params.sourceUrl, 'https://example.com');
    expect(result.word, 'lexicon');
  });
}
