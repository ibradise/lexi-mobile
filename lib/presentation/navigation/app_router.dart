import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../bloc/add_word_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/review_queue_bloc.dart';
import '../bloc/review_session_bloc.dart';
import '../bloc/review_session_event.dart';
import '../bloc/word_detail_bloc.dart';
import '../bloc/word_detail_event.dart';
import '../pages/add_words_page.dart';
import '../pages/main_shell_page.dart';
import '../pages/review_session_page.dart';
import '../pages/word_detail_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _shellRoute(settings, initialIndex: 0);
      case AppRoutes.vocabularyLibrary:
        return _shellRoute(settings, initialIndex: 1);
      case AppRoutes.review:
        return _shellRoute(settings, initialIndex: 2);
      case AppRoutes.reviewSession:
        return MaterialPageRoute<void>(
          builder: (_) => BlocProvider<ReviewSessionBloc>(
            create: (_) =>
                getIt<ReviewSessionBloc>()..add(const StartReviewSession()),
            child: const ReviewSessionPage(),
          ),
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
      case AppRoutes.wordDetail:
        final wordId = settings.arguments;
        if (wordId is! String) {
          return null;
        }
        return MaterialPageRoute<void>(
          builder: (_) => BlocProvider<WordDetailBloc>(
            create: (_) =>
                getIt<WordDetailBloc>(param1: wordId)
                  ..add(const LoadWordDetail()),
            child: const WordDetailPage(),
          ),
          settings: settings,
        );
    }
    return null;
  }

  static Route<void> _shellRoute(
    RouteSettings settings, {
    required int initialIndex,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>(create: (_) => getIt<DashboardBloc>()),
          BlocProvider<LibraryBloc>(
            create: (_) => getIt<LibraryBloc>()..add(const LoadLibrary()),
          ),
          BlocProvider<ReviewQueueBloc>(
            create: (_) => getIt<ReviewQueueBloc>(),
          ),
        ],
        child: MainShellPage(initialIndex: initialIndex),
      ),
      settings: settings,
    );
  }
}
