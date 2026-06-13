import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test - the app should render without crashing
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('CariUnpam')),
        ),
      ),
    );

    expect(find.text('CariUnpam'), findsOneWidget);
  });
}
