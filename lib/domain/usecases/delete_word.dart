import '../repositories/vocabulary_repository.dart';

class DeleteWord {
  const DeleteWord(this._repository);

  final VocabularyRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteWord(id.trim());
  }
}
