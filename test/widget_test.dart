
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/main.dart';

void main() {
  testWidgets('LORIS home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LorisApp());

    expect(find.text('LORIS'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('RESUME GAME'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
