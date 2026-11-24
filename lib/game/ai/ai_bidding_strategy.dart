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

/// Estimates trick-taking strength from the AI's own eight cards only.
///
/// The estimate deliberately avoids looking at undealt/opponents' cards. It
/// rewards sure winners, protected honours and a long suit that can become
/// trump, while discounting unsupported middle honours.
class AiBiddingStrategy {
  const AiBiddingStrategy();

  AiBidDecision chooseBid({
    required List<Card> hand,
    required int playerIndex,
    required int? highestBid,
    required int? highestBidder,
    int playerCount = 6,
  }) {
    _validateHand(hand);
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError.value(playerCount, 'playerCount');
    }
    if (playerIndex < 0 || playerIndex >= playerCount) {
      throw ArgumentError.value(playerIndex, 'playerIndex');
    }
    if (highestBid != null && (highestBid < 4 || highestBid > 8)) {
      throw ArgumentError.value(highestBid, 'highestBid');
    }
    if (highestBidder != null &&
        (highestBidder < 0 || highestBidder >= playerCount)) {
      throw ArgumentError.value(highestBidder, 'highestBidder');
    }

    // A partner has already committed the team's contract. Do not compete.
    if (highestBidder != null && highestBidder % 2 == playerIndex % 2) {
      return AiBidDecision(
        bidAmount: null,
        estimatedStrength: evaluateHand(hand),
      );
    }

    final strength = evaluateHand(hand);
    final targetBid = _bidForStrength(strength);
    if (targetBid == null || (highestBid != null && targetBid <= highestBid)) {
      return AiBidDecision(
        bidAmount: null,
        estimatedStrength: strength,
      );
    }

    return AiBidDecision(
      bidAmount: targetBid,
      estimatedStrength: strength,
    );
  }

  /// Returns an approximate number of tricks the hand can support.
  double evaluateHand(List<Card> hand) {
    _validateHand(hand);

    final suitCounts = <Suit, int>{for (final suit in Suit.values) suit: 0};
    for (final card in hand) {
      if (!card.isLoris && card.suit != null) {
        suitCounts[card.suit!] = suitCounts[card.suit!]! + 1;
      }
    }

    var strength = 0.65; // baseline for leading and positional opportunities
    for (final card in hand) {
      if (card.isLoris) {
        strength += 1.45; // the guaranteed highest card
        continue;
      }

      final suit = card.suit;
      final rank = card.rank;
      if (suit == null || rank == null) continue;
      final length = suitCounts[suit] ?? 0;

      switch (rank) {
        case 14: // Ace is normally a near-certain winner.
          strength += 0.95;
          break;
        case 13: // King is much safer when supported by another card.
          strength += length >= 2 ? 0.58 : 0.28;
          break;
        case 12:
          strength += length >= 3 ? 0.34 : 0.12;
          break;
        case 11:
          strength += length >= 4 ? 0.18 : 0.05;
          break;
        default:
          break;
      }
    }

    // A long suit offers a plausible trump source and can create extra tricks.
    final lengths = suitCounts.values.toList()..sort();
    for (final length in lengths) {
      if (length == 4) strength += 0.35;
      if (length == 5) strength += 0.65;
      if (length >= 6) strength += 0.65 + ((length - 5) * 0.28);
    }

    // Short side suits can be useful once a trump suit is established, but
    // give only a modest bonus because the AI does not know the chosen trump.
    final voids = suitCounts.values.where((count) => count == 0).length;
    strength += voids * 0.08;

    return strength;
  }

  void _validateHand(List<Card> hand) {
    if (hand.length != 8) {
      throw ArgumentError('AI hand must contain 8 cards.');
    }

    if (hand.toSet().length != hand.length) {
      throw ArgumentError('AI hand cannot contain duplicate cards.');
    }

    for (final card in hand) {
      if (card.isLoris) {
        final replacedRank = card.replacesRank;
        if (card.suit != null ||
            card.rank != null ||
            replacedRank == null ||
            replacedRank < 3 ||
            replacedRank > 14) {
          throw ArgumentError('AI hand contains an invalid LORIS card.');
        }
      } else if (card.suit == null ||
          card.rank == null ||
          card.rank! < 3 ||
          card.rank! > 14) {
        throw ArgumentError('AI hand contains an invalid normal card.');
      }
    }
  }

  int? _bidForStrength(double strength) {
    if (strength >= 7.0) return 8;
    if (strength >= 6.1) return 7;
    if (strength >= 5.2) return 6;
    if (strength >= 4.3) return 5;
    if (strength >= 3.4) return 4;
    return null;
  }
}
