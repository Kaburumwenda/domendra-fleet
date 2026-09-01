import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App boots and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const DomendraApp());
    expect(find.text('Domendra'), findsAtLeast(1));
  });
}
