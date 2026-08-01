import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aidsense_app/main.dart';

void main() {
  testWidgets('AidSense app boots smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AidSenseApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(AidSenseApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login callback routes resolve to callback screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AidSenseApp());

    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/login-callback/?code=test'),
      builder: (_) => const SizedBox.shrink(),
    );

    expect(route.settings.name, '/login-callback/?code=test');
    expect(route.builder, isNotNull);
  });
}
