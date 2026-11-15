
import '../models/loris_card.dart';

class AiBidDecision {
  final int? bidAmount;
  final double estimatedStrength;

  const AiBidDecision({
    required this.bidAmount,
    required this.estimatedStrength,
  });

  bool get shouldPass => bidAmount == null;
}

class AiBiddingStrategy {
  const AiBiddingStrategy();

  AiBidDecision chooseBid({
    required List<Card> hand,
    required int playerIndex,
    required int? highestBid,
    required int? highestBidder,
  }) {
    if (hand.length != 8) {
      throw ArgumentError('AI hand must contain 8 cards.');
    }

    // Never compete against a teammate's bid.
    if (highestBidder != null &&
        highestBidder % 2 == playerIndex % 2) {
      return const AiBidDecision(
        bidAmount: null,
        estimatedStrength: 0,
      );
    }

    final strength = evaluateHand(hand);

    int targetBid;

    if (strength >= 7.2) {
      targetBid = 8;
    } else if (strength >= 6.4) {
      targetBid = 7;
    } else if (strength >= 5.6) {
      targetBid = 6;
    } else if (strength >= 4.8) {
      targetBid = 5;
    } else if (strength >= 4.0) {
      targetBid = 4;
    } else {
      targetBid = 0;
    }

    if (highestBid != null && targetBid <= highestBid) {
      return AiBidDecision(
        bidAmount: null,
        estimatedStrength: strength,
      );
    }

    return AiBidDecision(
      bidAmount: targetBid == 0 ? null : targetBid,
      estimatedStrength: strength,
    );
  }

  double evaluateHand(List<Card> hand) {
    double strength = 2.3;

    final suitCounts = <Suit, int>{
      for (final suit in Suit.values) suit: 0,
    };

    for (final card in hand) {
      if (card.isLoris) {
        strength += 1.7;
        continue;
      }

      final suit = card.suit;
      final rank = card.rank;

      if (suit == null || rank == null) continue;

      suitCounts[suit] = (suitCounts[suit] ?? 0) + 1;

      switch (rank) {
        case 14:
          strength += 1.0;
          break;
        case 13:
          strength += 0.7;
          break;
        case 12:
          strength += 0.45;
          break;
        case 11:
          strength += 0.25;
          break;
      }
    }

    // Reward longer suits.
    for (final count in suitCounts.values) {
      if (count > 3) {
        strength += (count - 3) * 0.25;
      }
    }

    return strength;
  }
}
