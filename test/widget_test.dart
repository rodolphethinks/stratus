import 'package:flutter_test/flutter_test.dart';
import 'package:stratus/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const StratusApp());
    expect(find.byType(StratusApp), findsOneWidget);
  });
}
