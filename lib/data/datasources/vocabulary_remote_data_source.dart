import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/vocabulary_query.dart';
import '../models/bulk_add_result_model.dart';
import '../models/vocabulary_word_model.dart';
import '../models/word_detail_model.dart';
import '../models/word_list_page_model.dart';
import '../models/word_summary_model.dart';

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

  Future<WordListPageModel> getWords(VocabularyQuery query) async {
    final search = query.search?.trim();
    final params = <String, dynamic>{
      'sort': query.sort.wireValue,
      'order': query.order.wireValue,
      'page': query.page,
      'limit': query.limit,
    };

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (query.status != null) {
      params['status'] = query.status!.wireValue;
    }

    final response = await _apiClient.get(
      '/vocabulary',
      query: params,
      timeout: AppConfig.requestTimeout,
    );
    final data = response.data;
    final meta = response.meta;

    if (data is! List || meta == null) {
      throw const ApiException.parsing();
    }

    try {
      return WordListPageModel(
        items: [
          for (final item in data)
            if (item is Map<String, dynamic>) WordSummaryModel.fromJson(item),
        ],
        page: meta.page,
        limit: meta.limit,
        total: meta.total,
        totalPages: meta.totalPages,
      );
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }

  Future<WordDetailModel> getWordDetail(String id) async {
    final response = await _apiClient.get(
      '/vocabulary/${Uri.encodeComponent(id)}',
      timeout: AppConfig.requestTimeout,
    );

    return _parseDetail(response.data);
  }

  Future<void> deleteWord(String id) async {
    final response = await _apiClient.delete(
      '/vocabulary/${Uri.encodeComponent(id)}',
      timeout: AppConfig.requestTimeout,
    );
    final data = response.data;

    if (data is! Map<String, dynamic> || data['isArchived'] != true) {
      throw const ApiException.parsing();
    }
  }

  Future<WordDetailModel> regenerateAi(String id) async {
    final response = await _apiClient.post(
      '/vocabulary/${Uri.encodeComponent(id)}/regenerate-ai',
      timeout: AppConfig.aiRequestTimeout,
    );

    return _parseDetail(response.data);
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

  WordDetailModel _parseDetail(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException.parsing();
    }

    try {
      return WordDetailModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }
}
