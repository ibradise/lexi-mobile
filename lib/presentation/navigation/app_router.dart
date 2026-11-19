import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../bloc/add_word_bloc.dart';
import '../pages/add_words_page.dart';
import '../pages/home_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case AppRoutes.addWord:
        return MaterialPageRoute<void>(
          builder: (_) => BlocProvider<AddWordBloc>(
            create: (_) => getIt<AddWordBloc>(),
            child: const AddWordsPage(),
          ),
          settings: settings,
        );
    }
    return null;
  }
}