import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdeps_flutter/main.dart';

void main() {
  testWidgets('Muestra la pestaña Home por defecto', (WidgetTester tester) async {
    await tester.pumpWidget(const VantagePmoApp());

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.descendant(
      of: find.byType(IndexedStack),
      matching: find.text('Home'),
    ), findsOneWidget);
  });
}
