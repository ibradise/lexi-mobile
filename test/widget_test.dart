import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexi_mobile/core/di/injection.dart';
import 'package:lexi_mobile/main.dart';

void main() {
  testWidgets('app renders the home screen with the add words CTA', (
    tester,
  ) async {
    await tester.pumpWidget(const LexiApp());

    expect(find.text('Lexi'), findsWidgets);
    expect(find.text('Your vocabulary, learned.'), findsOneWidget);
    expect(find.byKey(const Key('homeAddWordsButton')), findsOneWidget);
    expect(find.text('Add words'), findsOneWidget);
  });

  testWidgets('opens the add words screen from home', (tester) async {
    configureDependencies(
      httpClient: MockClient(
        (_) async => http.Response('{"success":true,"data":null}', 200),
      ),
    );
    addTearDown(getIt.reset);

    await tester.pumpWidget(const LexiApp());
    await tester.tap(find.byKey(const Key('homeAddWordsButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add a word'), findsOneWidget);
    expect(find.byKey(const Key('wordField')), findsOneWidget);
  });
}
