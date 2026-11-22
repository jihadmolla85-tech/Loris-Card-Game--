import 'dart:math';

import '../models/loris_card.dart';

class TrumpSelectionResult {
  final Suit? trumpSuit;
  final int cardOwnerIndex;
  final Card selectedCard;
  final bool revealedToEveryone;
  final bool bidderHasTrumpSuit;

  const TrumpSelectionResult({
    required this.trumpSuit,
    required this.cardOwnerIndex,
    required this.selectedCard,
    required this.revealedToEveryone,
    required this.bidderHasTrumpSuit,
  });
}

class TrumpSelectionEngine {
  /// Randomly chooses one ordinary card from any teammate's hand.
  /// The caller uses only its suit; the selected card is never shown to players.
  static MapEntry<int, Card> selectRandomTeammateCard({
    required List<List<Card>> hands,
    required int bidderIndex,
    required Random random,
  }) {
    final playerCount = hands.length;
    if ((playerCount != 4 && playerCount != 6) ||
        bidderIndex < 0 ||
        bidderIndex >= playerCount) {
      throw ArgumentError('Invalid player count or bidder index.');
    }

    final eligible = <MapEntry<int, Card>>[];
    for (var playerIndex = 0; playerIndex < playerCount; playerIndex++) {
      if (playerIndex == bidderIndex ||
          playerIndex % 2 != bidderIndex % 2) {
        continue;
      }
      for (final card in hands[playerIndex]) {
        if (!card.isLoris && card.suit != null) {
          eligible.add(MapEntry(playerIndex, card));
        }
      }
    }

    if (eligible.isEmpty) {
      throw StateError('No eligible ordinary card exists in teammate hands.');
    }
    return eligible[random.nextInt(eligible.length)];
  }

  static TrumpSelectionResult select({
    required List<List<Card>> hands,
    required int bidderIndex,
    required int highestBidderIndex,
    required int cardOwnerIndex,
    required Card selectedCard,
  }) {
    final playerCount = hands.length;

    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (bidderIndex < 0 || bidderIndex >= playerCount ||
        cardOwnerIndex < 0 || cardOwnerIndex >= playerCount) {
      throw ArgumentError('Invalid player index.');
    }

    if (bidderIndex != highestBidderIndex) {
      throw StateError('Only the highest bidder can select trump.');
    }

    // A bidder may privately draw a random normal card from a teammate.
    // Opponent cards are never eligible, and the selected card is not revealed.
    if (cardOwnerIndex % 2 != bidderIndex % 2) {
      throw ArgumentError('Trump card must belong to the bidder or a teammate.');
    }

    if (!hands[cardOwnerIndex].contains(selectedCard)) {
      throw ArgumentError('Selected card is not in the owner hand.');
    }

    if (selectedCard.isLoris) {
      if (cardOwnerIndex != bidderIndex) {
        throw ArgumentError('The bidder must hold the LORIS Joker to select Joker mode.');
      }
      return TrumpSelectionResult(
        trumpSuit: null,
        cardOwnerIndex: cardOwnerIndex,
        selectedCard: selectedCard,
        revealedToEveryone: false,
        bidderHasTrumpSuit: true,
      );
    }
    if (selectedCard.suit == null) {
      throw ArgumentError('Selected card has no suit.');
    }

    final trumpSuit = selectedCard.suit!;

    final bidderHasTrumpSuit = hands.asMap().entries.any(
      (entry) => entry.key % 2 == bidderIndex % 2 &&
          entry.value.any((card) => !card.isLoris && card.suit == trumpSuit),
    );

    return TrumpSelectionResult(
      trumpSuit: trumpSuit,
      cardOwnerIndex: cardOwnerIndex,
      selectedCard: selectedCard,
      revealedToEveryone: false,
      bidderHasTrumpSuit: bidderHasTrumpSuit,
    );
  }
}
