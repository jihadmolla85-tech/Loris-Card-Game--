import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loris_card_game/main.dart';

void main() {
  testWidgets('supplied player portrait atlas is bundled', (WidgetTester tester) async {
    final image = await rootBundle.load('assets/images/loris_portrait_atlas.jpg');
    expect(image.lengthInBytes, greaterThan(1000));
  });

  testWidgets('audio preferences persist after reopening the app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LorisApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    final musicSwitch = find.widgetWithText(SwitchListTile, 'Background Music');
    final soundSwitch = find.widgetWithText(SwitchListTile, 'Sound Effects');
    expect(tester.widget<SwitchListTile>(musicSwitch).value, isTrue);
    expect(tester.widget<SwitchListTile>(soundSwitch).value, isTrue);

    await tester.tap(musicSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(musicSwitch).value, isFalse);

    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const LorisApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(musicSwitch).value, isFalse);
    expect(tester.widget<SwitchListTile>(soundSwitch).value, isTrue);
  });

  testWidgets('LORIS home screen loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LorisApp());

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/loris_logo.jpg',
      ),
      findsOneWidget,
    );
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
