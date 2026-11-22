import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/ai/ai_card_play_strategy.dart';
import 'package:loris_card_game/game/engine/trick_engine.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

Card c(Suit suit, int rank) => Card.normal(suit: suit, rank: rank);

List<List<Card>> handsWith(List<Card> playerZero, List<Card> playerOne,
    List<Card> playerTwo) {
  final used = {...playerZero, ...playerOne, ...playerTwo};
  final deck = <Card>[
    for (final suit in Suit.values)
      for (var rank = 3; rank <= 14; rank++) c(suit, rank),
  ]..removeWhere(used.contains);
  return [
    playerZero,
    playerOne,
    playerTwo,
    deck.take(8).toList(),
  ];
}

void main() {
  const strategy = AiCardPlayStrategy();

  group('AI card-play strategy', () {
    test('follows suit and preserves a partner winning the trick', () {
      final hand = [
        c(Suit.hearts, 7), c(Suit.hearts, 11), c(Suit.clubs, 4),
        c(Suit.clubs, 5), c(Suit.diamonds, 6), c(Suit.diamonds, 7),
        c(Suit.spades, 14), const Card.loris(replacesRank: 7),
      ];
      final engine = TrickEngine(
        hands: handsWith(
          [c(Suit.hearts, 14), ...List.generate(7, (i) => c(Suit.clubs, i + 3))],
          [c(Suit.hearts, 8), ...List.generate(7, (i) => c(Suit.diamonds, i + 3))],
          hand,
        ),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
      );
      engine.playCard(0, c(Suit.hearts, 14));
      engine.playCard(1, c(Suit.hearts, 8));

      final chosen = strategy.chooseCard(engine: engine, playerIndex: 2);
      expect(chosen, c(Suit.hearts, 7));
      expect(engine.legalCardsFor(2), contains(chosen));
    });

    test('uses the cheapest legal card that beats an opponent', () {
      final hand = [
        c(Suit.hearts, 9), c(Suit.hearts, 11), c(Suit.hearts, 14),
        c(Suit.clubs, 4), c(Suit.clubs, 5), c(Suit.diamonds, 6),
        c(Suit.diamonds, 7), const Card.loris(replacesRank: 7),
      ];
      final engine = TrickEngine(
        hands: handsWith(
          [c(Suit.hearts, 8), ...List.generate(7, (i) => c(Suit.clubs, i + 3))],
          [c(Suit.hearts, 10), ...List.generate(7, (i) => c(Suit.diamonds, i + 3))],
          hand,
        ),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
      );
      engine.playCard(0, c(Suit.hearts, 8));
      engine.playCard(1, c(Suit.hearts, 10));

      expect(strategy.chooseCard(engine: engine, playerIndex: 2), c(Suit.hearts, 11));
    });

    test('leads from a long side suit and does not waste LORIS', () {
      final hand = [
        c(Suit.clubs, 4), c(Suit.clubs, 5), c(Suit.clubs, 6),
        c(Suit.hearts, 14), c(Suit.hearts, 7), c(Suit.diamonds, 8),
        c(Suit.diamonds, 9), const Card.loris(replacesRank: 7),
      ];
      final engine = TrickEngine(
        hands: handsWith(
          hand,
          List.generate(8, (i) => c(Suit.hearts, i + 3)),
          List.generate(8, (i) => c(Suit.diamonds, i + 3)),
        ),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
      );

      expect(strategy.chooseCard(engine: engine, playerIndex: 0), c(Suit.clubs, 4));
    });

    test('never returns a card outside the rules engine legal set', () {
      final hand = [
        c(Suit.clubs, 4), c(Suit.hearts, 7), c(Suit.hearts, 9),
        c(Suit.diamonds, 6), c(Suit.diamonds, 8), c(Suit.spades, 10),
        c(Suit.spades, 12), const Card.loris(replacesRank: 7),
      ];
      final engine = TrickEngine(
        hands: handsWith(
          [c(Suit.hearts, 14), ...List.generate(7, (i) => c(Suit.clubs, i + 3))],
          List.generate(8, (i) => c(Suit.diamonds, i + 3)),
          hand,
        ),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
      );
      engine.playCard(0, c(Suit.hearts, 14));
      engine.playCard(1, c(Suit.diamonds, 3));

      final chosen = strategy.chooseCard(engine: engine, playerIndex: 2);
      expect(engine.legalCardsFor(2), contains(chosen));
    });

    test('leads from the longest ordinary suit in LORIS trump mode', () {
      final hand = [
        c(Suit.spades, 3), c(Suit.spades, 4), c(Suit.spades, 5),
        c(Suit.spades, 6), c(Suit.clubs, 14), c(Suit.hearts, 3),
        c(Suit.diamonds, 4), const Card.loris(replacesRank: 3),
      ];
      final engine = TrickEngine(
        hands: handsWith(
          hand,
          List.generate(8, (i) => c(Suit.hearts, i + 4)),
          List.generate(8, (i) => c(Suit.diamonds, i + 5)),
        ),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        lorisTrump: true,
      );

      expect(strategy.chooseCard(engine: engine, playerIndex: 0), c(Suit.spades, 3));
    });

    test('does not penalize the selected suit as ordinary trump in LORIS mode', () {
      final hand = [
        c(Suit.spades, 8), c(Suit.spades, 9), c(Suit.clubs, 10),
        c(Suit.diamonds, 10), c(Suit.clubs, 11), c(Suit.diamonds, 11),
        c(Suit.spades, 12), const Card.loris(replacesRank: 7),
      ];
      final engine = TrickEngine(
        hands: handsWith(
          [
            c(Suit.hearts, 14),
            ...List.generate(7, (i) => c(Suit.clubs, i + 3)),
          ],
          [
            c(Suit.hearts, 13),
            ...List.generate(7, (i) => c(Suit.diamonds, i + 3)),
          ],
          hand,
        ),
        dealerIndex: 3,
        trumpSuit: Suit.spades,
        lorisTrump: true,
      );
      engine.playCard(0, c(Suit.hearts, 14));
      engine.playCard(1, c(Suit.hearts, 13));

      expect(strategy.chooseCard(engine: engine, playerIndex: 2), c(Suit.spades, 8));
    });

    test('six-player decisions do not change when unseen hands are redistributed', () {
      final deck = <Card>[
        for (final suit in Suit.values)
          for (var rank = 3; rank <= 14; rank++)
            if (!(suit == Suit.spades && rank == 3)) c(suit, rank),
        const Card.loris(replacesRank: 3),
      ];
      final dealtHands = List.generate(
        6,
        (index) => deck.skip(index * 8).take(8).toList(),
      );
      final original = TrickEngine(
        hands: dealtHands.map(List<Card>.from).toList(),
        dealerIndex: 5,
        trumpSuit: Suit.spades,
      );

      original.playCard(0, original.legalCardsFor(0).first);
      original.playCard(1, original.legalCardsFor(1).first);

      final redistributed = original.hands.map(List<Card>.from).toList();
      // Exchange seven unplayed cards with player 3, preserving a valid
      // 7-card remainder for player 0 and an 8-card hand for player 3.
      final partnerRemainder = redistributed[0].toList();
      final hiddenOpponent = redistributed[3].toList();
      redistributed[0] = hiddenOpponent.take(7).toList();
      redistributed[3] = [
        ...partnerRemainder,
        hiddenOpponent.last,
      ];
      // Rotate the remaining hidden hands, including the AI's other teammate.
      final seatThree = redistributed[3];
      final seatFour = redistributed[4];
      final seatFive = redistributed[5];
      redistributed[3] = seatFour;
      redistributed[4] = seatFive;
      redistributed[5] = seatThree;

      final alternate = TrickEngine(
        hands: redistributed,
        dealerIndex: 5,
        trumpSuit: Suit.spades,
        initialPlays: original.plays,
        restoredFirstPlayerIndex: original.firstPlayerIndex,
      );

      final originalChoice = strategy.chooseCard(
        engine: original,
        playerIndex: 2,
      );
      final alternateChoice = strategy.chooseCard(
        engine: alternate,
        playerIndex: 2,
      );

      expect(alternateChoice, originalChoice);
      expect(original.legalCardsFor(2), contains(originalChoice));
      expect(alternate.legalCardsFor(2), contains(alternateChoice));
    });
  });
}
