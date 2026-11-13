import 'dart:math';

import '../models/loris_card.dart';

class DealerSelectionResult {
  final int dealerIndex;
  final Card jackCard;
  final List<Card> drawnCards;
  final List<Card> shuffledDeck;

  const DealerSelectionResult({
    required this.dealerIndex,
    required this.jackCard,
    required this.drawnCards,
    required this.shuffledDeck,
  });
}

class InitialDealerSelector {
  static DealerSelectionResult select({
    required List<Card> deck,
    required int playerCount,
    required int firstPlayerIndex,
    Random? random,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (deck.length != playerCount * 8) {
      throw ArgumentError('Invalid deck size.');
    }

    if (firstPlayerIndex < 0 ||
        firstPlayerIndex >= playerCount) {
      throw ArgumentError('Invalid starting player.');
    }

    final drawnCards = <Card>[];

    for (var i = 0; i < deck.length; i++) {
      final card = deck[i];
      final currentPlayer =
          (firstPlayerIndex + i) % playerCount;

      drawnCards.add(card);

      if (!card.isLoris && card.rank == 11) {
        final shuffledDeck = List<Card>.from(deck);
        shuffledDeck.shuffle(random ?? Random());

        return DealerSelectionResult(
          dealerIndex: currentPlayer,
          jackCard: card,
          drawnCards: List.unmodifiable(drawnCards),
          shuffledDeck: List.unmodifiable(shuffledDeck),
        );
      }
    }

    throw StateError('No Jack found in the deck.');
  }
}
