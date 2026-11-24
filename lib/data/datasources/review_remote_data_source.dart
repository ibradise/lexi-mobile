import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/review_history_query.dart';
import '../../domain/entities/review_submission.dart';
import '../models/review_exercise_model.dart';
import '../models/review_history_model.dart';
import '../models/review_queue_model.dart';
import '../models/review_submission_result_model.dart';

class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ReviewQueueModel> getTodayReview() async {
    final response = await _apiClient.get(
      '/review/today',
      timeout: AppConfig.requestTimeout,
    );

    final data = _requireMap(response.data);
    try {
      return ReviewQueueModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }

  Future<ReviewExerciseSetModel> getExercises(String wordId) async {
    final response = await _apiClient.get(
      '/vocabulary/${Uri.encodeComponent(wordId)}/exercises',
      timeout: AppConfig.requestTimeout,
    );

    final data = _requireMap(response.data);
    try {
      return ReviewExerciseSetModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }

  Future<ReviewHistoryPageModel> getHistory(ReviewHistoryQuery query) async {
    final wordId = query.wordId?.trim();
    final params = <String, dynamic>{'page': query.page, 'limit': query.limit};

    if (wordId != null && wordId.isNotEmpty) {
      params['wordId'] = wordId;
    }

    final response = await _apiClient.get(
      '/review/history',
      query: params,
      timeout: AppConfig.requestTimeout,
    );
    final data = response.data;
    final meta = response.meta;

    if (data is! List || meta == null) {
      throw const ApiException.parsing();
    }

    try {
      return ReviewHistoryPageModel(
        items: [
          for (final item in data)
            if (item is Map<String, dynamic>)
              ReviewHistoryItemModel.fromJson(item),
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

  Future<ReviewSubmissionResultModel> submitReview(
    ReviewSubmission submission,
  ) async {
    final body = <String, dynamic>{
      'exerciseId': submission.exerciseId,
      'hintUsed': submission.hintUsed,
      'skipped': submission.skipped,
    };

    if (submission.userAnswer != null) {
      body['userAnswer'] = submission.userAnswer;
    }
    if (submission.responseTimeMs != null) {
      body['responseTimeMs'] = submission.responseTimeMs;
    }
    if (submission.submissionId != null) {
      body['submissionId'] = submission.submissionId;
    }

    final response = await _apiClient.post(
      '/review/${Uri.encodeComponent(submission.wordId)}/submit',
      body: body,
      timeout: AppConfig.requestTimeout,
    );

    final data = _requireMap(response.data);
    try {
      return ReviewSubmissionResultModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }

  Map<String, dynamic> _requireMap(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException.parsing();
    }
    return data;
  }
}
