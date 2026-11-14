import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/deal_controller.dart';
import 'package:loris_card_game/game/engine/deck_shuffle_engine.dart';
import 'package:loris_card_game/game/engine/redeal_controller.dart';
import 'package:loris_card_game/game/engine/redeal_validation_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Deal Controller', () {
    late DealController controller;

    setUp(() {
      controller = DealController(
        shuffleEngine: DeckShuffleEngine(),
        redealController: RedealController(
          validationEngine: RedealValidationEngine(),
        ),
      );
    });

    List<Card> createDeck(int playerCount) {
      final ranks = playerCount == 4
          ? List.generate(8, (i) => i + 7)
          : List.generate(12, (i) => i + 3);

      return [
        for (final suit in Suit.values)
          for (final rank in ranks)
            if (!(suit == Suit.spades && rank == ranks.first))
              Card.normal(suit: suit, rank: rank),
        Card.loris(replacesRank: ranks.first),
      ];
    }

    test('Deals 32 cards to four players', () {
      final hands = controller.deal(
        deck: createDeck(4),
        playerCount: 4,
        dealerIndex: 0,
      );

      expect(hands.length, 4);
      expect(hands.every((hand) => hand.length == 8), isTrue);
      expect(hands.expand((hand) => hand).length, 32);
    });

    test('Deals 48 cards to six players', () {
      final hands = controller.deal(
        deck: createDeck(6),
        playerCount: 6,
        dealerIndex: 2,
      );

      expect(hands.length, 6);
      expect(hands.every((hand) => hand.length == 8), isTrue);
      expect(hands.expand((hand) => hand).length, 48);
    });

    test('Starts dealing from the dealer right', () {
      final deck = createDeck(4);

      final hands = controller.deal(
        deck: deck,
        playerCount: 4,
        dealerIndex: 1,
      );

      expect(hands[2].length, 8);
      expect(controller.dealerIndex, 1);
    });

    test('Keeps the same dealer after redeal', () {
      controller.deal(
        deck: createDeck(4),
        playerCount: 4,
        dealerIndex: 2,
      );

      controller.validateDeal(
        everyonePassed: true,
        bidderHasTrumpSuit: false,
      );

      final newHands = controller.redeal();

      expect(controller.dealerIndex, 2);
      expect(newHands.length, 4);
      expect(newHands.every((hand) => hand.length == 8), isTrue);
      expect(controller.shouldRedeal, isFalse);
    });

    test('Rejects redeal when validation does not require it', () {
      controller.deal(
        deck: createDeck(4),
        playerCount: 4,
        dealerIndex: 0,
      );

      controller.validateDeal(
        everyonePassed: false,
        bidderHasTrumpSuit: true,
      );

      expect(
        () => controller.redeal(),
        throwsStateError,
      );
    });

    test('Rejects invalid player count', () {
      expect(
        () => controller.deal(
          deck: createDeck(4),
          playerCount: 5,
          dealerIndex: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid dealer index', () {
      expect(
        () => controller.deal(
          deck: createDeck(4),
          playerCount: 4,
          dealerIndex: 4,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid deck size', () {
      expect(
        () => controller.deal(
          deck: createDeck(4).sublist(0, 31),
          playerCount: 4,
          dealerIndex: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Throws when validating before dealing', () {
      expect(
        () => controller.validateDeal(
          everyonePassed: true,
          bidderHasTrumpSuit: false,
        ),
        throwsStateError,
      );
    });
  });
}
