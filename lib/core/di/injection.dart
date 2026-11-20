import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/vocabulary_remote_data_source.dart';
import '../../data/repositories/vocabulary_repository_impl.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/usecases/add_word.dart';
import '../../domain/usecases/add_words.dart';
import '../../domain/usecases/delete_word.dart';
import '../../domain/usecases/get_word_detail.dart';
import '../../domain/usecases/get_words.dart';
import '../../domain/usecases/regenerate_word_ai.dart';
import '../../presentation/bloc/add_word_bloc.dart';
import '../../presentation/bloc/library_bloc.dart';
import '../../presentation/bloc/word_detail_bloc.dart';
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

  getIt.registerLazySingleton<VocabularyRemoteDataSource>(
    () => VocabularyRemoteDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<VocabularyRepository>(
    () => VocabularyRepositoryImpl(getIt<VocabularyRemoteDataSource>()),
  );

  getIt.registerLazySingleton<AddWord>(
    () => AddWord(getIt<VocabularyRepository>()),
  );
  getIt.registerLazySingleton<AddWords>(
    () => AddWords(getIt<VocabularyRepository>()),
  );
  getIt.registerLazySingleton<GetWords>(
    () => GetWords(getIt<VocabularyRepository>()),
  );
  getIt.registerLazySingleton<GetWordDetail>(
    () => GetWordDetail(getIt<VocabularyRepository>()),
  );
  getIt.registerLazySingleton<DeleteWord>(
    () => DeleteWord(getIt<VocabularyRepository>()),
  );
  getIt.registerLazySingleton<RegenerateWordAi>(
    () => RegenerateWordAi(getIt<VocabularyRepository>()),
  );

  getIt.registerFactory<AddWordBloc>(
    () => AddWordBloc(getIt<AddWord>(), getIt<AddWords>()),
  );
  getIt.registerFactory<LibraryBloc>(() => LibraryBloc(getIt<GetWords>()));
  getIt.registerFactoryParam<WordDetailBloc, String, void>(
    (wordId, _) => WordDetailBloc(
      getIt<GetWordDetail>(),
      getIt<RegenerateWordAi>(),
      getIt<DeleteWord>(),
      wordId: wordId,
    ),
  );
}
