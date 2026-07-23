import 'package:flutter_test/flutter_test.dart';
import 'package:kredit_pintar/main.dart';

void main() {
  testWidgets('App should start', (WidgetTester tester) async {
    await tester.pumpWidget(const KreditPintarApp());
    expect(find.text('Kredit Pintar'), findsOneWidget);
  });
}
