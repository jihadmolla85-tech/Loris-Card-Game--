import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/deck_shuffle_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Deck Shuffle Engine', () {
    late DeckShuffleEngine engine;

    setUp(() {
      engine = DeckShuffleEngine();
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

    test('Preserves all cards in a four-player deck', () {
      final deck = createDeck(4);

      final shuffled = engine.shuffle(deck);

      expect(shuffled.length, 32);
      expect(shuffled.toSet(), deck.toSet());
      expect(shuffled.toSet().length, 32);
    });

    test('Preserves all cards in a six-player deck', () {
      final deck = createDeck(6);

      final shuffled = engine.shuffle(deck);

      expect(shuffled.length, 48);
      expect(shuffled.toSet(), deck.toSet());
      expect(shuffled.toSet().length, 48);
    });

    test('Does not modify the original deck', () {
      final deck = createDeck(4);
      final originalDeck = List<Card>.from(deck);

      engine.shuffle(deck);

      expect(deck, originalDeck);
    });

    test('Returns a new list', () {
      final deck = createDeck(4);

      final shuffled = engine.shuffle(deck);

      expect(identical(shuffled, deck), isFalse);
    });

    test('Supports an empty deck', () {
      final shuffled = engine.shuffle([]);

      expect(shuffled, isEmpty);
    });

    test('Supports a deck with one card', () {
      final card = Card.normal(
        suit: Suit.hearts,
        rank: 10,
      );

      final shuffled = engine.shuffle([card]);

      expect(shuffled, [card]);
    });
  });
}
