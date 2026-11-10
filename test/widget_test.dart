import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdeps_flutter/app.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';

String es(String key, [List<Object?> args = const []]) => AppStrings.lookup('es', key, args);

void main() {
  testWidgets('Muestra el splash y luego la pantalla de login', (tester) async {
    await tester.pumpWidget(const VantagePmoApp());

    expect(find.text('Vantage PMO'), findsOneWidget);
    expect(find.text(es('auth_version', [appVersion])), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text(es('auth_welcome_back')), findsOneWidget);
    expect(find.text(es('iam_login_sign_in')), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
