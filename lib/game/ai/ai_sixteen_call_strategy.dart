import '../models/loris_card.dart';

/// Makes a conservative 16-call decision from public round progress and the
/// AI player's own remaining hand only. It never reads another player's hand.
class AiSixteenCallStrategy {
  const AiSixteenCallStrategy();

  bool shouldCall({
    required List<Card> hand,
    required int completedTricks,
    required Suit trumpSuit,
    required bool lorisTrump,
  }) {
    if (completedTricks < 1 || completedTricks >= 8) {
      throw ArgumentError.value(completedTricks, 'completedTricks');
    }

    final remainingTricks = 8 - completedTricks;
    if (hand.length != remainingTricks) {
      throw ArgumentError(
        'AI hand must contain one card for each remaining trick.',
      );
    }
    if (hand.toSet().length != hand.length) {
      throw ArgumentError('AI hand cannot contain duplicate cards.');
    }

    final ranksBySuit = <Suit, List<int>>{
      for (final suit in Suit.values) suit: <int>[],
    };
    var potential = 0.0;

    for (final card in hand) {
      if (card.isLoris) {
        if (card.suit != null || card.rank != null) {
          throw ArgumentError('AI hand contains an invalid LORIS card.');
        }
        // LORIS is the strongest single-card control in either trump mode.
        potential += 1.25;
        continue;
      }

      final suit = card.suit;
      final rank = card.rank;
      if (suit == null || rank == null || rank < 3 || rank > 14) {
        throw ArgumentError('AI hand contains an invalid normal card.');
      }
      ranksBySuit[suit]!.add(rank);

      final heldRanks = ranksBySuit[suit]!;
      final hasAce = heldRanks.contains(14) || rank == 14;
      final hasKing = heldRanks.contains(13) || rank == 13;
      final hasQueen = heldRanks.contains(12) || rank == 12;

      potential += switch (rank) {
        14 => 1.0,
        13 => hasAce ? 0.48 : 0.18,
        12 => hasAce && hasKing ? 0.26 : 0.08,
        11 => hasAce && hasKing && hasQueen ? 0.14 : 0.04,
        _ => 0.0,
      };

      if (!lorisTrump && suit == trumpSuit) {
        potential += switch (rank) {
          14 => 0.30,
          13 => 0.20,
          12 => 0.10,
          11 => 0.05,
          _ => 0.0,
        };
      }
    }

    // A long suit can provide several leads. A concentrated high trump suit
    // is especially valuable because it can draw opposing trumps first.
    for (final ranks in ranksBySuit.values) {
      if (ranks.length > 2) {
        potential += (ranks.length - 2) * 0.12;
      }
    }

    if (!lorisTrump) {
      final trumpLength = ranksBySuit[trumpSuit]!.length;
      if (trumpLength > 1) {
        potential += (trumpLength - 1) * 0.35;
      }
    }

    // Requiring almost one point of control per remaining trick keeps the
    // AI from making a risky 16 call on a few unsupported honours.
    return potential >= remainingTricks * 0.90;
  }
}
