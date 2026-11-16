
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/main.dart';

void main() {
  testWidgets('LORIS home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LorisApp());

    expect(find.text('LORIS'), findsOneWidget);
    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('RESUME GAME'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('HOW TO PLAY'), findsOneWidget);

    await tester.tap(find.text('HOW TO PLAY'));
    await tester.pumpAndSettle();

    expect(find.text('HOW TO PLAY LORIS'), findsOneWidget);
    expect(find.text('GAME SETUP'), findsOneWidget);
    expect(find.text('CALL 16'), findsOneWidget);
    expect(find.text('SCORING'), findsOneWidget);

    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();
  });
}
