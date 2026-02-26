// Basic Flutter widget test for Super Linux Utility

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app launches without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
