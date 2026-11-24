import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/domain/entities/paginated_result.dart';
import 'package:lexi_mobile/domain/entities/vocabulary_query.dart';
import 'package:lexi_mobile/domain/entities/word_detail.dart';
import 'package:lexi_mobile/domain/entities/word_summary.dart';
import 'package:lexi_mobile/domain/repositories/vocabulary_repository.dart';
import 'package:lexi_mobile/domain/usecases/delete_word.dart';
import 'package:lexi_mobile/domain/usecases/get_word_detail.dart';
import 'package:lexi_mobile/domain/usecases/get_words.dart';
import 'package:lexi_mobile/domain/usecases/regenerate_word_ai.dart';
import 'package:mocktail/mocktail.dart';

class MockVocabularyRepository extends Mock implements VocabularyRepository {}

void main() {
  late MockVocabularyRepository repository;

  setUpAll(() {
    registerFallbackValue(const VocabularyQuery());
  });

  setUp(() {
    repository = MockVocabularyRepository();
  });

  test('GetWords trims search and bounds pagination', () async {
    when(() => repository.getWords(any())).thenAnswer(
      (_) async => const PaginatedResult<WordSummary>(
        items: [],
        page: 1,
        limit: 100,
        total: 0,
        totalPages: 0,
      ),
    );

    await GetWords(repository)(
      const VocabularyQuery(search: '  lex  ', page: 0, limit: 500),
    );

    final query =
        verify(() => repository.getWords(captureAny())).captured.single
            as VocabularyQuery;

    expect(query.search, 'lex');
    expect(query.page, 1);
    expect(query.limit, 100);
  });

  test('GetWords clears a blank search', () async {
    when(() => repository.getWords(any())).thenAnswer(
      (_) async => const PaginatedResult<WordSummary>(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0,
      ),
    );

    await GetWords(repository)(const VocabularyQuery(search: '   '));

    final query =
        verify(() => repository.getWords(captureAny())).captured.single
            as VocabularyQuery;

    expect(query.search, isNull);
  });

  test('detail, delete, and regenerate trim ids', () async {
    const detail = WordDetail(
      summary: WordSummary(
        id: 'word-1',
        word: 'lexicon',
        difficulty: 3,
        aiReady: true,
      ),
    );
    when(() => repository.getWordDetail('word-1'))
        .thenAnswer((_) async => detail);
    when(() => repository.regenerateAi('word-1'))
        .thenAnswer((_) async => detail);
    when(() => repository.deleteWord('word-1')).thenAnswer((_) async {});

    expect((await GetWordDetail(repository)(' word-1 ')).summary.id, 'word-1');
    expect(
      (await RegenerateWordAi(repository)(' word-1 ')).summary.id,
      'word-1',
    );
    await DeleteWord(repository)(' word-1 ');

    verify(() => repository.getWordDetail('word-1')).called(1);
    verify(() => repository.regenerateAi('word-1')).called(1);
    verify(() => repository.deleteWord('word-1')).called(1);
  });
}
