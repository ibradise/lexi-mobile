import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/bulk_add_result_model.dart';
import '../models/vocabulary_word_model.dart';

class VocabularyRemoteDataSource {
  const VocabularyRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<VocabularyWordModel> addWord({
    required String word,
    String? context,
    String? sourceTitle,
    String? sourceUrl,
  }) async {
    final body = <String, dynamic>{'word': word};

    if (context != null) {
      body['sourceContext'] = context;
    }
    if (sourceTitle != null) {
      body['sourceTitle'] = sourceTitle;
    }
    if (sourceUrl != null) {
      body['sourceUrl'] = sourceUrl;
    }

    final response = await _apiClient.post(
      '/vocabulary',
      body: body,
      timeout: AppConfig.aiRequestTimeout,
    );

    return _parseWord(response.data);
  }

  Future<BulkAddResultModel> addWords(List<String> words) async {
    final response = await _apiClient.post(
      '/vocabulary',
      body: {'words': words},
      timeout: AppConfig.requestTimeout,
    );

    return _parseBulkResult(response.data);
  }

  VocabularyWordModel _parseWord(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException.parsing();
    }

    try {
      return VocabularyWordModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }

  BulkAddResultModel _parseBulkResult(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException.parsing();
    }

    try {
      return BulkAddResultModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }
}
