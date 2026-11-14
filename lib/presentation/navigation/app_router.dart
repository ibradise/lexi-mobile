import 'package:flutter/material.dart';

import '../pages/placeholder_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const PlaceholderPage(),
          settings: settings,
        );
    }
    return null;
  }
}
