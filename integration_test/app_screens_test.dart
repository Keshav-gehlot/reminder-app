// Drives the app on an emulator in CI and saves screenshots of the main
// screens. Run with:
// flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_screens_test.dart
import 'package:cybertrack12/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> settle(WidgetTester tester, [int seconds = 2]) async {
  // Web views and progress spinners never fully settle, so pump for a while.
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  if (f.evaluate().isEmpty) return;
  await tester.tap(f.first);
  await settle(tester);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture main screens', (tester) async {
    app.main();
    await settle(tester, 5);
    await binding.convertFlutterSurfaceToImage();
    await settle(tester, 1);

    final onLogin = find.text('Get started').evaluate().isNotEmpty ||
        find.text('Continue without an account').evaluate().isNotEmpty;
    if (onLogin) {
      await binding.takeScreenshot('01-welcome');
      await tapText(tester, 'Get started');
      await tapText(tester, 'Continue without an account');
      await settle(tester, 3);
    }
    await binding.takeScreenshot('02-home');

    await tapText(tester, 'Study');
    await binding.takeScreenshot('03-study');

    await tapText(tester, 'Arrays and hash maps');
    await settle(tester, 4);
    await binding.takeScreenshot('04-lesson-learn');

    final quizTab = find.widgetWithText(Tab, 'Quiz');
    if (quizTab.evaluate().isNotEmpty) {
      await tester.tap(quizTab);
      await settle(tester);
      await binding.takeScreenshot('05-lesson-quiz');
    }
    final back = find.byTooltip('Back');
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
      await settle(tester);
    }

    await tapText(tester, 'CTF');
    await binding.takeScreenshot('06-study-ctf');

    await tapText(tester, 'Plan');
    await binding.takeScreenshot('07-plan');

    await tapText(tester, 'Track');
    await binding.takeScreenshot('08-track');
  });
}
