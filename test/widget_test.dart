import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexi_mobile/core/di/injection.dart';
import 'package:lexi_mobile/main.dart';

void main() {
  void configureWithEmptyLibrary() {
    configureDependencies(
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'meta': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
            }),
            200,
          );
        }
        return http.Response('{"success":true,"data":null}', 200);
      }),
    );
    addTearDown(getIt.reset);
  }

  testWidgets('app renders the dashboard with bottom navigation', (
    tester,
  ) async {
    configureWithEmptyLibrary();
    await tester.pumpWidget(const LexiApp());
    await tester.pumpAndSettle();

    expect(find.text('Your vocabulary, learned.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('mainDashboardTab')), findsOneWidget);
    expect(find.byKey(const Key('mainLibraryTab')), findsOneWidget);
    expect(find.byKey(const Key('mainAddWordButton')), findsOneWidget);
  });

  testWidgets('switches between dashboard and library tabs', (tester) async {
    configureWithEmptyLibrary();
    await tester.pumpWidget(const LexiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mainLibraryTab')));
    await tester.pumpAndSettle();

    expect(find.text('Vocabulary Library'), findsOneWidget);
    expect(find.text('No words yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mainDashboardTab')));
    await tester.pumpAndSettle();

    expect(find.text('Your vocabulary, learned.'), findsOneWidget);
  });

  testWidgets('opens the add words screen from the shell', (tester) async {
    configureWithEmptyLibrary();
    await tester.pumpWidget(const LexiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mainAddWordButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add a word'), findsOneWidget);
    expect(find.byKey(const Key('wordField')), findsOneWidget);
  });
}
