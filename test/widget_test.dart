import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_mobile/main.dart';

void main() {
  testWidgets('app renders the Lexi shell', (tester) async {
    await tester.pumpWidget(const LexiApp());

    expect(find.text('Lexi'), findsWidgets);
    expect(find.text('Your vocabulary, learned.'), findsOneWidget);
  });
}
