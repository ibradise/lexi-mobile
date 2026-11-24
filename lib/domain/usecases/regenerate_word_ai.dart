import '../entities/word_detail.dart';
import '../repositories/vocabulary_repository.dart';

class RegenerateWordAi {
  const RegenerateWordAi(this._repository);

  final VocabularyRepository _repository;

  Future<WordDetail> call(String id) {
    return _repository.regenerateAi(id.trim());
  }
}
