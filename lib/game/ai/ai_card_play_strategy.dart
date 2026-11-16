import '../engine/trick_engine.dart';
import '../models/loris_card.dart';

/// Chooses only from TrickEngine.legalCardsFor, so strategy can never bypass
/// the rules engine. It evaluates only the AI hand and cards already on table.
class AiCardPlayStrategy {
  const AiCardPlayStrategy();

  Card chooseCard({
    required TrickEngine engine,
    required int playerIndex,
  }) {
    final legal = engine.legalCardsFor(playerIndex);
    if (legal.isEmpty) {
      throw StateError('No legal cards are available for this turn.');
    }
    if (legal.length == 1) return legal.first;

    final hand = engine.hands[playerIndex];
    final plays = List<TrickPlay>.unmodifiable(engine.plays);
    final nonLoris = legal.where((card) => !card.isLoris).toList();

    if (plays.isEmpty) {
      return _chooseLead(nonLoris.isEmpty ? legal : nonLoris, hand, engine.trumpSuit);
    }

    final currentWinner = _winnerOf(plays, engine.trumpSuit);
    final partnerIsWinning = currentWinner % 2 == playerIndex % 2;

    if (partnerIsWinning) {
      // Save LORIS, honours and trump while following the compulsory rules.
      return _cheapest(legal, engine.trumpSuit);
    }

    final cardsThatWin = legal.where((card) {
      final simulated = [
        ...plays,
        TrickPlay(playerIndex: playerIndex, card: card),
      ];
      return _winnerOf(simulated, engine.trumpSuit) == playerIndex;
    }).toList();

    // Spend the least valuable card that actually takes the trick.
    if (cardsThatWin.isNotEmpty) {
      return _cheapest(cardsThatWin, engine.trumpSuit);
    }

    // The trick cannot be won: discard the least valuable legal card.
    return _cheapest(legal, engine.trumpSuit);
  }

  Card _chooseLead(List<Card> candidates, List<Card> hand, Suit trumpSuit) {
    final sideSuitCards = candidates
        .where((card) => !card.isLoris && card.suit != trumpSuit)
        .toList();
    final pool = sideSuitCards.isNotEmpty ? sideSuitCards : candidates;

    final counts = <Suit, int>{for (final suit in Suit.values) suit: 0};
    for (final card in hand) {
      if (!card.isLoris && card.suit != null) {
        counts[card.suit!] = counts[card.suit!]! + 1;
      }
    }

    pool.sort((a, b) {
      final aCount = counts[a.suit] ?? 0;
      final bCount = counts[b.suit] ?? 0;
      if (aCount != bCount) return bCount.compareTo(aCount);

      // Cash a protected ace; otherwise lead a low card from the long suit.
      final aAce = a.rank == 14 ? 1 : 0;
      final bAce = b.rank == 14 ? 1 : 0;
      if (aAce != bAce) return bAce.compareTo(aAce);
      return (a.rank ?? 0).compareTo(b.rank ?? 0);
    });

    return pool.first;
  }

  Card _cheapest(List<Card> cards, Suit trumpSuit) {
    final sorted = List<Card>.from(cards)
      ..sort((a, b) => _cardCost(a, trumpSuit).compareTo(_cardCost(b, trumpSuit)));
    return sorted.first;
  }

  int _cardCost(Card card, Suit trumpSuit) {
    if (card.isLoris) return 1000;
    final rank = card.rank ?? 0;
    final honourCost = switch (rank) {
      14 => 80,
      13 => 55,
      12 => 35,
      11 => 20,
      _ => rank,
    };
    return honourCost + (card.suit == trumpSuit ? 25 : 0);
  }

  int _winnerOf(List<TrickPlay> plays, Suit trumpSuit) {
    final lorisPlay = plays.where((play) => play.card.isLoris);
    if (lorisPlay.isNotEmpty) return lorisPlay.first.playerIndex;

    final firstCard = plays.first.card;
    final ledSuit = firstCard.isLoris ? Suit.spades : firstCard.suit;
    final trumpPlays = plays
        .where((play) => !play.card.isLoris && play.card.suit == trumpSuit)
        .toList();
    final candidates = trumpPlays.isNotEmpty
        ? trumpPlays
        : plays.where((play) => play.card.suit == ledSuit).toList();

    return candidates.reduce((best, next) =>
        (next.card.rank ?? 0) > (best.card.rank ?? 0) ? next : best).playerIndex;
  }
}
