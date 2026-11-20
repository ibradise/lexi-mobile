import '../../domain/entities/add_word_params.dart';
import '../../domain/entities/bulk_add_result.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../datasources/vocabulary_remote_data_source.dart';
import 'exception_mapper.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  const VocabularyRepositoryImpl(this._remoteDataSource);

  final VocabularyRemoteDataSource _remoteDataSource;

  @override
  Future<VocabularyWord> addWord(AddWordParams params) async {
    try {
      final model = await _remoteDataSource.addWord(
        word: params.word,
        context: params.context,
        sourceTitle: params.sourceTitle,
        sourceUrl: params.sourceUrl,
      );
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<BulkAddResult> addWords(List<String> words) async {
    try {
      final model = await _remoteDataSource.addWords(words);
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }
}
