
class DealerRotationEngine {
  /// Returns the next dealer when a new round begins.
  /// Rotate only when the dealer's team earned at least +1 point this round.
  /// The score argument is the round delta, never the cumulative match total.
  static int nextDealerIndex({
    required int currentDealerIndex,
    required int playerCount,
    required int dealerTeamScore,
    required bool isRedeal,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (currentDealerIndex < 0 ||
        currentDealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }

    // Redeal: keep the same dealer.
    if (isRedeal) {
      return currentDealerIndex;
    }

    // Dealer's team has not reached +1: keep the same dealer.
    if (dealerTeamScore < 1) {
      return currentDealerIndex;
    }

    // New round: move to the player on the dealer's right.
    return (currentDealerIndex + 1) % playerCount;
  }
}
