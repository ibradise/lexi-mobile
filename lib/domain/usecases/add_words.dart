import '../entities/bulk_add_result.dart';
import '../repositories/vocabulary_repository.dart';

class AddWords {
  const AddWords(this._repository);

  final VocabularyRepository _repository;

  Future<BulkAddResult> call(String input) {
    return _repository.addWords([input.trim()]);
  }
}
