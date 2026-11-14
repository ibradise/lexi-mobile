import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../network/api_client.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies({http.Client? httpClient, String? baseUrl}) {
  getIt.registerSingleton<http.Client>(
    httpClient ?? http.Client(),
    dispose: (client) => client.close(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(client: getIt<http.Client>(), baseUrl: baseUrl),
  );
}
