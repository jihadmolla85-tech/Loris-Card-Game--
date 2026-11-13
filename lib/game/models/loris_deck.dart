import 'dart:math';

import 'loris_card.dart';

class LorisDeck {
  static List<Card> create(
    PlayerCount playerCount, {
    Random? random,
  }) {
    final lowestRank = playerCount == PlayerCount.four ? 7 : 3;
    final cards = <Card>[];

    for (final suit in Suit.values) {
      for (var rank = lowestRank; rank <= 14; rank++) {
        if (suit == Suit.spades && rank == lowestRank) {
          continue;
        }

        cards.add(Card.normal(suit: suit, rank: rank));
      }
    }

    cards.add(Card.loris(replacesRank: lowestRank));
    cards.shuffle(random ?? Random());

    return cards;
  }
}
