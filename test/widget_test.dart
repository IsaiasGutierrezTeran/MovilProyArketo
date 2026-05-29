// Basic smoke test for the Arketo app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
