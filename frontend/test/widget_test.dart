import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Canteen App initial render test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CanteenApp());
    expect(find.byType(CanteenApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
