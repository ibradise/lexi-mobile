import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/domain/entities/added_word.dart';
import 'package:lexi_mobile/domain/entities/bulk_add_result.dart';
import 'package:lexi_mobile/domain/repositories/vocabulary_repository.dart';
import 'package:lexi_mobile/domain/usecases/add_words.dart';
import 'package:mocktail/mocktail.dart';

class MockVocabularyRepository extends Mock implements VocabularyRepository {}

void main() {
  late MockVocabularyRepository repository;

  setUp(() {
    repository = MockVocabularyRepository();
  });

  test('trims the pasted input and delegates a single raw entry', () async {
    when(() => repository.addWords(['lexicon, syntax'])).thenAnswer(
      (_) async => const BulkAddResult(
        added: [AddedWord(id: 'word-1', word: 'lexicon')],
        duplicates: [],
        invalid: [],
      ),
    );

    final result = await AddWords(repository)('  lexicon, syntax  ');

    verify(() => repository.addWords(['lexicon, syntax'])).called(1);
    expect(result.added.single.word, 'lexicon');
  });
}
