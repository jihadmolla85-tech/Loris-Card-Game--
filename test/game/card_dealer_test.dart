
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/card_dealer.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS Card Dealer', () {
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

    test('Deals 8 cards to each of 4 players in two groups of 4', () {
      final deck = createDeck(4);

      final hands = CardDealer.deal(
        deck: deck,
        playerCount: 4,
        firstPlayerIndex: 2,
      );

      expect(hands.length, 4);

      for (var player = 0; player < 4; player++) {
        expect(hands[player].length, 8);

        final offset = (player - 2 + 4) % 4;

        expect(
          hands[player].take(4).toList(),
          [for (var i = 0; i < 4; i++) deck[offset + i * 4]],
        );

        expect(
          hands[player].skip(4).toList(),
          [for (var i = 0; i < 4; i++) deck[16 + offset + i * 4]],
        );
      }
    });

    test('Deals 8 cards to each of 6 players in two groups of 4', () {
      final deck = createDeck(6);

      final hands = CardDealer.deal(
        deck: deck,
        playerCount: 6,
        firstPlayerIndex: 4,
      );

      expect(hands.length, 6);
      expect(hands.every((hand) => hand.length == 8), isTrue);
      expect(hands.expand((hand) => hand).length, 48);

      for (var player = 0; player < 6; player++) {
        final offset = (player - 4 + 6) % 6;

        expect(
          hands[player].take(4).toList(),
          [for (var i = 0; i < 4; i++) deck[offset + i * 6]],
        );

        expect(
          hands[player].skip(4).toList(),
          [for (var i = 0; i < 4; i++) deck[24 + offset + i * 6]],
        );
      }
    });

    test('Rejects invalid player count', () {
      expect(
        () => CardDealer.deal(
          deck: createDeck(4),
          playerCount: 5,
          firstPlayerIndex: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid deck size', () {
      expect(
        () => CardDealer.deal(
          deck: createDeck(4).sublist(0, 31),
          playerCount: 4,
          firstPlayerIndex: 0,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid first player index', () {
      expect(
        () => CardDealer.deal(
          deck: createDeck(4),
          playerCount: 4,
          firstPlayerIndex: 4,
        ),
        throwsArgumentError,
      );
    });
  });
}
