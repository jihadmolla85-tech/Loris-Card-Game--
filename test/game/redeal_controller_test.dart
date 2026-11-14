import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/redeal_controller.dart';
import 'package:loris_card_game/game/engine/redeal_validation_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Redeal Controller', () {
    late RedealController controller;

    setUp(() {
      controller = RedealController(
        validationEngine: RedealValidationEngine(),
      );
    });

    List<Card> normalHand() {
  return List.generate(
    8,
    (index) => Card.normal(
      suit: Suit.hearts,
      rank: 10 + (index % 5),
    ),
  );
}

    List<List<Card>> validHands() {
      return List.generate(4, (_) => normalHand());
    }

    test('Stores validation result when redeal is required', () {
      final result = controller.validate(
        hands: validHands(),
        dealerIndex: 2,
        everyonePassed: true,
        bidderHasTrumpSuit: false,
      );

      expect(result.shouldRedeal, isTrue);
      expect(controller.shouldRedeal, isTrue);
      expect(controller.lastResult, same(result));
      expect(controller.dealerIndex, 2);
    });

    test('Does not request redeal when all conditions are valid', () {
      final result = controller.validate(
        hands: validHands(),
        dealerIndex: 1,
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, isFalse);
      expect(controller.shouldRedeal, isFalse);
      expect(controller.dealerIndex, 1);
    });

    test('Keeps the same dealer after redeal validation', () {
      final result = controller.validate(
        hands: validHands(),
        dealerIndex: 3,
        everyonePassed: true,
        bidderHasTrumpSuit: false,
      );

      expect(result.sameDealerIndex, 3);
      expect(controller.dealerIndex, 3);
    });

    test('Reset clears the previous validation result', () {
      controller.validate(
        hands: validHands(),
        dealerIndex: 0,
        everyonePassed: true,
        bidderHasTrumpSuit: false,
      );

      controller.reset();

      expect(controller.lastResult, isNull);
      expect(controller.shouldRedeal, isFalse);
      expect(controller.dealerIndex, isNull);
    });

    test('Supports six-player redeal validation', () {
      final hands = List.generate(6, (_) => normalHand());

      final result = controller.validate(
        hands: hands,
        dealerIndex: 5,
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(result.shouldRedeal, isFalse);
      expect(controller.dealerIndex, 5);
    });

    test('Rejects invalid player count', () {
      expect(
        () => controller.validate(
          hands: List.generate(5, (_) => normalHand()),
          dealerIndex: 0,
          everyonePassed: true,
          bidderHasTrumpSuit: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
