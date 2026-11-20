import '../../domain/entities/add_word_params.dart';
import '../../domain/entities/bulk_add_result.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/vocabulary_query.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/word_detail.dart';
import '../../domain/entities/word_summary.dart';
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

  @override
  Future<PaginatedResult<WordSummary>> getWords(VocabularyQuery query) async {
    try {
      final model = await _remoteDataSource.getWords(query);
      return model.toEntity<WordSummary>((summary) => summary.toEntity());
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<WordDetail> getWordDetail(String id) async {
    try {
      final model = await _remoteDataSource.getWordDetail(id);
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<void> deleteWord(String id) async {
    try {
      await _remoteDataSource.deleteWord(id);
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }

  @override
  Future<WordDetail> regenerateAi(String id) async {
    try {
      final model = await _remoteDataSource.regenerateAi(id);
      return model.toEntity();
    } catch (error, stackTrace) {
      throw mapExceptionToFailure(error, stackTrace);
    }
  }
}
