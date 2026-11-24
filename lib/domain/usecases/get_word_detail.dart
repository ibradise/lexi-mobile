import '../entities/word_detail.dart';
import '../repositories/vocabulary_repository.dart';

class GetWordDetail {
  const GetWordDetail(this._repository);

  final VocabularyRepository _repository;

  Future<WordDetail> call(String id) {
    return _repository.getWordDetail(id.trim());
  }
}
