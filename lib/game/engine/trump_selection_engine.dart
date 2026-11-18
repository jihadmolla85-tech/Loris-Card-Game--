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

    // Trump must be declared from the winning bidder's own eight cards.
    // Teammate cards are never exposed or used to select the trump suit.
    if (cardOwnerIndex != bidderIndex) {
      throw ArgumentError('Trump must be selected from the bidder own hand.');
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

    final bidderHasTrumpSuit = hands[bidderIndex].any(
      (card) => !card.isLoris && card.suit == trumpSuit,
    );

    return TrumpSelectionResult(
      trumpSuit: trumpSuit,
      cardOwnerIndex: cardOwnerIndex,
      selectedCard: selectedCard,
      revealedToEveryone: cardOwnerIndex != bidderIndex,
      bidderHasTrumpSuit: bidderHasTrumpSuit,
    );
  }
}
