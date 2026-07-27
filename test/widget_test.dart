import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noesis_flutter/main.dart';

void main() {
  testWidgets('home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

