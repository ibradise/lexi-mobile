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
        if (request.method == 'GET' &&
            request.url.path.endsWith('/dashboard')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'todayReview': {
                  'due': 0,
                  'newWords': 0,
                  'needAttention': 0,
                  'becomingStrong': 0,
                },
                'weakestWords': [],
                'stats': {
                  'totalWords': 0,
                  'new': 0,
                  'learning': 0,
                  'familiar': 0,
                  'strong': 0,
                  'mastered': 0,
                  'reviewsToday': 0,
                  'accuracyLast7Days': 0,
                  'currentStreak': 0,
                },
              },
              'error': null,
              'meta': null,
            }),
            200,
          );
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/review/today')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalDue': 0,
                'newWords': 0,
                'reviewWords': 0,
                'queue': [],
              },
              'error': null,
              'meta': null,
            }),
            200,
          );
        }
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
    expect(find.byKey(const Key('mainReviewTab')), findsOneWidget);
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

  testWidgets('opens the review tab and shows the empty state', (tester) async {
    configureWithEmptyLibrary();
    await tester.pumpWidget(const LexiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mainReviewTab')));
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.byKey(const Key('reviewStartButton')), findsNothing);
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
