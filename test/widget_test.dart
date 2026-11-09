import 'package:flutter_test/flutter_test.dart';
import 'package:mdeps_flutter/main.dart';

void main() {
  testWidgets('Muestra la pantalla de login al iniciar', (WidgetTester tester) async {
    await tester.pumpWidget(const VantagePmoApp());

    expect(find.text('Vantage PMO'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
