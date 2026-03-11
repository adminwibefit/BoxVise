import 'package:flutter_test/flutter_test.dart';
import 'package:boxwise/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BoxwiseApp());
    expect(find.text('Boxwise'), findsOneWidget);
  });
}
