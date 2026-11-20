import '../entities/add_word_params.dart';
import '../entities/bulk_add_result.dart';
import '../entities/vocabulary_word.dart';

abstract interface class VocabularyRepository {
  Future<VocabularyWord> addWord(AddWordParams params);

  Future<BulkAddResult> addWords(List<String> words);
}
