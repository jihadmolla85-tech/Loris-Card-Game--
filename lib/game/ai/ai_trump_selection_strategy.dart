import '../models/loris_card.dart';

/// Selects trump using only the bidding AI's own hand.
///
/// The bidder may reveal one eligible teammate card under LORIS rules, but
/// the AI deliberately does not inspect a teammate's hidden cards. That keeps
/// its decision within information the bidder is entitled to know.
class AiTrumpSelectionStrategy {
  const AiTrumpSelectionStrategy();

  Card chooseCard({required List<Card> bidderHand}) {
    if (bidderHand.length != 8) {
      throw ArgumentError('AI bidder hand must contain 8 cards.');
    }

    final cardsBySuit = <Suit, List<Card>>{
      for (final suit in Suit.values) suit: <Card>[],
    };

    for (final card in bidderHand) {
      if (!card.isLoris && card.suit != null && card.rank != null) {
        cardsBySuit[card.suit!]!.add(card);
      }
    }

    final candidates = cardsBySuit.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (candidates.isEmpty) {
      throw StateError('The AI bidder has no card that can select trump.');
    }

    candidates.sort((a, b) {
      final aScore = _suitStrength(a.value);
      final bScore = _suitStrength(b.value);
      final byStrength = bScore.compareTo(aScore);
      if (byStrength != 0) return byStrength;
      return a.key.index.compareTo(b.key.index);
    });

    // The selected card stays in the hand. Reveal the lowest card in the
    // strongest suit rather than unnecessarily exposing a high honour.
    final selectedSuitCards = List<Card>.from(candidates.first.value)
      ..sort((a, b) => (a.rank ?? 0).compareTo(b.rank ?? 0));
    return selectedSuitCards.first;
  }

  int _suitStrength(List<Card> cards) {
    final rankTotal = cards.fold<int>(
      0,
      (total, card) => total + (card.rank ?? 0),
    );
    // Suit length dominates; honours break ties between equally long suits.
    return cards.length * 100 + rankTotal;
  }
}
