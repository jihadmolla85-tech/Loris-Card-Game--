
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/deck_validation_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Deck Validation Engine', () {
    late DeckValidationEngine engine;

    setUp(() {
      engine = DeckValidationEngine();
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

    test('Accepts a valid 32-card four-player deck', () {
      final result = engine.validate(
        deck: createDeck(4),
        playerCount: 4,
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Accepts a valid 48-card six-player deck', () {
      final result = engine.validate(
        deck: createDeck(6),
        playerCount: 6,
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Rejects invalid player count', () {
      final result = engine.validate(
        deck: createDeck(4),
        playerCount: 5,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(DeckValidationError.invalidPlayerCount),
      );
    });

    test('Rejects invalid deck size', () {
      final result = engine.validate(
        deck: createDeck(4).sublist(0, 31),
        playerCount: 4,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(DeckValidationError.invalidDeckSize),
      );
    });

    test('Rejects missing LORIS card', () {
      final deck = createDeck(4)
          .where((card) => !card.isLoris)
          .toList();

      final result = engine.validate(
        deck: deck,
        playerCount: 4,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(DeckValidationError.incorrectLorisCount),
      );
    });

    test('Rejects duplicate normal card', () {
      final deck = createDeck(4);
      deck[1] = deck[0];

      final result = engine.validate(
        deck: deck,
        playerCount: 4,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(DeckValidationError.duplicateCard),
      );
    });

    test('Rejects incorrect LORIS replacement rank', () {
      final deck = createDeck(4);
      deck[deck.length - 1] = Card.loris(replacesRank: 8);

      final result = engine.validate(
        deck: deck,
        playerCount: 4,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(DeckValidationError.incorrectLorisReplacement),
      );
    });

    test('Rejects a normal card with invalid rank', () {
      final deck = createDeck(4);
      deck[0] = Card.normal(
        suit: Suit.clubs,
        rank: 3,
      );

      final result = engine.validate(
        deck: deck,
        playerCount: 4,
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(DeckValidationError.invalidCardRank),
      );
    });
  });
}
