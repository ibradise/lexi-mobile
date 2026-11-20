import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardModel> getDashboard() async {
    final response = await _apiClient.get(
      '/dashboard',
      timeout: AppConfig.requestTimeout,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException.parsing();
    }

    try {
      return DashboardModel.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException.parsing(details: error);
    }
  }
}
