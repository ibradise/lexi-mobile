import '../entities/add_word_params.dart';
import '../entities/bulk_add_result.dart';
import '../entities/paginated_result.dart';
import '../entities/vocabulary_query.dart';
import '../entities/vocabulary_word.dart';
import '../entities/word_detail.dart';
import '../entities/word_summary.dart';

abstract interface class VocabularyRepository {
  Future<VocabularyWord> addWord(AddWordParams params);

  Future<BulkAddResult> addWords(List<String> words);

  Future<PaginatedResult<WordSummary>> getWords(VocabularyQuery query);

  Future<WordDetail> getWordDetail(String id);

  Future<void> deleteWord(String id);

  Future<WordDetail> regenerateAi(String id);
}
