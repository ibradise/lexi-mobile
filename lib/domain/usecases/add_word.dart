import '../entities/add_word_params.dart';
import '../entities/vocabulary_word.dart';
import '../repositories/vocabulary_repository.dart';

class AddWord {
  const AddWord(this._repository);

  final VocabularyRepository _repository;

  Future<VocabularyWord> call(AddWordParams params) {
    return _repository.addWord(
      AddWordParams(
        word: params.word.trim(),
        context: _normalizeOptional(params.context),
        sourceTitle: _normalizeOptional(params.sourceTitle),
        sourceUrl: _normalizeOptional(params.sourceUrl),
      ),
    );
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
