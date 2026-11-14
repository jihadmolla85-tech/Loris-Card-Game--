
import '../models/loris_card.dart';

enum RedealReason {
  everyonePassed,
  allCardsBelowTen,
  bidderHasNoTrump,
}

class RedealResult {
  final bool shouldRedeal;
  final List<RedealReason> reasons;
  final int sameDealerIndex;

  const RedealResult({
    required this.shouldRedeal,
    required this.reasons,
    required this.sameDealerIndex,
  });
}

class RedealValidationEngine {
  RedealResult evaluate({
    required List<List<Card>> hands,
    required int dealerIndex,
    required bool everyonePassed,
    required bool bidderHasTrumpSuit,
  }) {
    if (hands.length != 4 && hands.length != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex < 0 || dealerIndex >= hands.length) {
      throw ArgumentError('Invalid dealer index.');
    }

    for (final hand in hands) {
      if (hand.length != 8) {
        throw ArgumentError('Each player must have 8 cards.');
      }
    }

    final reasons = <RedealReason>[];

    if (everyonePassed) {
      reasons.add(RedealReason.everyonePassed);
    }

    final hasLowHand = hands.any((hand) {
  return hand.every((card) {
    if (card.isLoris) return false;
    return card.rank != null && card.rank! < 10;
  });
}); {
      final normalCards = hand.where((card) => !card.isLoris).toList();

      return normalCards.isNotEmpty &&
          normalCards.every(
            (card) => card.rank != null && card.rank! < 10,
          );
    });

    if (hasLowHand) {
      reasons.add(RedealReason.allCardsBelowTen);
    }

    if (!everyonePassed && !bidderHasTrumpSuit) {
      reasons.add(RedealReason.bidderHasNoTrump);
    }

    return RedealResult(
      shouldRedeal: reasons.isNotEmpty,
      reasons: reasons,
      sameDealerIndex: dealerIndex,
    );
  }
}
