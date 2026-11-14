
class DealerRotationEngine {
  /// Returns the next dealer when a new round begins.
  /// The next dealer is the player to the current dealer's right.
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
