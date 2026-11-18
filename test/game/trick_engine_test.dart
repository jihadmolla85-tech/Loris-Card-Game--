import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';
import 'package:loris_card_game/game/engine/trick_engine.dart';

Card card(Suit suit, int rank) =>
    Card.normal(suit: suit, rank: rank);

void main() {
  group('LORIS Trick Engine', () {
    late List<List<Card>> hands;

    setUp(() {
      hands = [
        [
          card(Suit.hearts, 10),
          card(Suit.spades, 8),
          card(Suit.clubs, 9),
          card(Suit.diamonds, 9),
          card(Suit.hearts, 7),
          card(Suit.spades, 9),
          card(Suit.clubs, 10),
          card(Suit.diamonds, 10),
        ],
        [
          card(Suit.hearts, 12),
          card(Suit.spades, 7),
          card(Suit.clubs, 8),
          card(Suit.diamonds, 8),
          card(Suit.hearts, 8),
          card(Suit.spades, 10),
          card(Suit.clubs, 11),
          card(Suit.diamonds, 11),
        ],
        [
          card(Suit.hearts, 14),
          card(Suit.spades, 11),
          card(Suit.clubs, 7),
          card(Suit.diamonds, 7),
          card(Suit.hearts, 9),
          card(Suit.spades, 12),
          card(Suit.clubs, 12),
          card(Suit.diamonds, 12),
        ],
        [
          card(Suit.hearts, 11),
          card(Suit.spades, 13),
          card(Suit.clubs, 13),
          card(Suit.diamonds, 13),
          card(Suit.hearts, 13),
          card(Suit.spades, 14),
          card(Suit.clubs, 14),
          card(Suit.diamonds, 14),
        ],
      ];
    });

    test('first player is dealer right', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      expect(game.firstPlayerIndex, 1);
      expect(game.currentPlayerIndex, 1);
    });

    test('players must follow led suit', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      game.playCard(1, card(Suit.hearts, 12));

      expect(
        () => game.playCard(2, card(Suit.spades, 11)),
        throwsArgumentError,
      );
    });

    test('player without led suit may play another suit', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      game.playCard(1, card(Suit.hearts, 12));

      hands[2].removeWhere(
        (c) => c.suit == Suit.hearts,
      );

      game.playCard(2, card(Suit.spades, 11));

      expect(game.plays.length, 2);
    });

    test('LORIS may be played at any time', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      final loris = Card.loris(replacesRank: 7);
      hands[2].add(loris);

      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, loris);

      expect(game.plays.length, 2);
    });

    test('LORIS always wins the trick', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      final loris = Card.loris(replacesRank: 7);
      hands[2].add(loris);

      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, loris);
      game.playCard(3, card(Suit.hearts, 13));
      game.playCard(0, card(Suit.hearts, 10));

      expect(game.winnerIndex, 2);
    });

    test('Joker mode compares the rank of every suit', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: null,
      );
      hands[2].removeWhere((c) => c.suit == Suit.hearts);
      hands[3].removeWhere((c) => c.suit == Suit.hearts);
      hands[0].removeWhere((c) => c.suit == Suit.hearts);

      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, card(Suit.spades, 11));
      game.playCard(3, card(Suit.diamonds, 13));
      game.playCard(0, card(Suit.clubs, 10));

      expect(game.winnerIndex, 3);
    });

    test('Joker beats every card in Joker mode', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: null,
      );
      final joker = Card.loris(replacesRank: 7);
      hands[2].add(joker);

      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, joker);
      game.playCard(3, card(Suit.hearts, 13));
      game.playCard(0, card(Suit.hearts, 10));

      expect(game.winnerIndex, 2);
    });

    test('highest trump wins when trump is played', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      hands[2].removeWhere(
        (c) => c.suit == Suit.hearts,
      );

      hands[0].removeWhere(
        (c) => c.suit == Suit.hearts,
      );

      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, card(Suit.spades, 11));
      game.playCard(3, card(Suit.hearts, 13));
      game.playCard(0, card(Suit.spades, 8));

      expect(game.winnerIndex, 2);
    });

    test('highest led suit wins without trump', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, card(Suit.hearts, 14));
      game.playCard(3, card(Suit.hearts, 13));
      game.playCard(0, card(Suit.hearts, 10));

      expect(game.winnerIndex, 2);
    });

    test('LORIS first means Spades is led', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.hearts,
      );

      final loris = Card.loris(replacesRank: 7);
      hands[1].add(loris);

      game.playCard(1, loris);

      expect(game.ledSuit, Suit.spades);
    });

    test('Spades must be followed after first LORIS', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.hearts,
      );

      final loris = Card.loris(replacesRank: 7);
      hands[1].add(loris);

      game.playCard(1, loris);

      expect(
        () => game.playCard(2, card(Suit.hearts, 14)),
        throwsArgumentError,
      );
    });

    test('LORIS wins even when it leads the trick', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.hearts,
      );

      final loris = Card.loris(replacesRank: 7);
      hands[1].add(loris);

      game.playCard(1, loris);
      game.playCard(2, card(Suit.spades, 11));
      game.playCard(3, card(Suit.spades, 13));
      game.playCard(0, card(Suit.spades, 8));

      expect(game.winnerIndex, 1);
    });

    test('cards are removed after being played', () {
      final playedCard = card(Suit.hearts, 12);

      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      game.playCard(1, playedCard);

      expect(hands[1].contains(playedCard), false);
    });

    test('cannot play out of turn', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      expect(
        () => game.playCard(
          0,
          card(Suit.hearts, 10),
        ),
        throwsStateError,
      );
    });

    test('winner unavailable before trick completes', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );

      expect(
        () => game.winnerIndex,
        throwsStateError,
      );
    });

    test('may discard any suit when void in the led suit, even while holding trump', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );
      hands[2].removeWhere((c) => c.suit == Suit.hearts);
      game.playCard(1, card(Suit.hearts, 12));

      expect(game.legalCardsFor(2), contains(card(Suit.clubs, 7)));
      game.playCard(2, card(Suit.clubs, 7));
      expect(game.plays.last.card, card(Suit.clubs, 7));
    });

    test('may play a lower trump when a higher trump is already in the trick', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );
      hands[2].removeWhere((c) => c.suit == Suit.hearts);
      hands[2].add(card(Suit.spades, 14));
      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, card(Suit.spades, 11));

      hands[3].removeWhere((c) => c.suit == Suit.hearts);
      hands[3].add(card(Suit.spades, 8));

      expect(game.legalCardsFor(3), contains(card(Suit.spades, 8)));
      game.playCard(3, card(Suit.spades, 8));
      expect(game.plays.last.card, card(Suit.spades, 8));
    });

    test('may play a lower trump when no higher trump is held', () {
      final game = TrickEngine(
        hands: hands,
        dealerIndex: 0,
        trumpSuit: Suit.spades,
      );
      hands[2].removeWhere((c) => c.suit == Suit.hearts);
      hands[2].add(card(Suit.spades, 14));
      game.playCard(1, card(Suit.hearts, 12));
      game.playCard(2, card(Suit.spades, 14));

      hands[3].removeWhere((c) => c.suit == Suit.hearts);
      expect(
        game.legalCardsFor(3).any((c) => c.suit == Suit.spades),
        isTrue,
      );
      game.playCard(3, card(Suit.spades, 13));
      expect(game.plays.length, 3);
    });

  });
}
