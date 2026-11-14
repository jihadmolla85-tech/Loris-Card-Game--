
import '../models/loris_card.dart';

enum DeckValidationError {
  invalidPlayerCount,
  invalidDeckSize,
  incorrectLorisCount,
  duplicateCard,
  invalidCardRank,
  invalidCardSuit,
  missingCard,
  incorrectLorisReplacement,
}

class DeckValidationResult {
  final bool isValid;
  final List<DeckValidationError> errors;

  const DeckValidationResult({
    required this.isValid,
    required this.errors,
  });
}

class DeckValidationEngine {
  DeckValidationResult validate({
    required List<Card> deck,
    required int playerCount,
  }) {
    final errors = <DeckValidationError>[];

    if (playerCount != 4 && playerCount != 6) {
      errors.add(DeckValidationError.invalidPlayerCount);

      return DeckValidationResult(
        isValid: false,
        errors: errors,
      );
    }

    final expectedSize = playerCount * 8;

    if (deck.length != expectedSize) {
      errors.add(DeckValidationError.invalidDeckSize);
    }

    final expectedRanks = playerCount == 4
        ? List.generate(8, (i) => i + 7)
        : List.generate(12, (i) => i + 3);

    final expectedLorisRank = expectedRanks.first;

    final lorisCards = deck.where((card) => card.isLoris).toList();

    if (lorisCards.length != 1) {
      errors.add(DeckValidationError.incorrectLorisCount);
    }

    for (final card in lorisCards) {
      if (card.replacesRank != expectedLorisRank) {
        errors.add(
          DeckValidationError.incorrectLorisReplacement,
        );
      }
    }

    final normalCards = deck.where((card) => !card.isLoris).toList();

    final seenCards = <Card>{};

    for (final card in normalCards) {
      if (card.suit == null) {
        errors.add(DeckValidationError.invalidCardSuit);
        continue;
      }

      if (card.rank == null ||
          !expectedRanks.contains(card.rank)) {
        errors.add(DeckValidationError.invalidCardRank);
        continue;
      }

      if (!seenCards.add(card)) {
        errors.add(DeckValidationError.duplicateCard);
      }
    }

    final expectedCards = <Card>{
      for (final suit in Suit.values)
        for (final rank in expectedRanks)
          if (!(suit == Suit.spades && rank == expectedLorisRank))
            Card.normal(suit: suit, rank: rank),
    };

    if (seenCards.length == expectedCards.length &&
        !seenCards.containsAll(expectedCards)) {
      errors.add(DeckValidationError.missingCard);
    } else if (seenCards.length != expectedCards.length) {
      errors.add(DeckValidationError.missingCard);
    }

    return DeckValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
