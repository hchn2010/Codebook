import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic Flutter test harness works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Codebook'))),
    );
    expect(find.text('Codebook'), findsOneWidget);
  });
}
