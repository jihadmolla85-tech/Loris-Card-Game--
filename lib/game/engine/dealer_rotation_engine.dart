class DealerRotationEngine {
  /// Returns the next dealer when a new round begins.
  /// Rotate only when the dealer team's cumulative match total is +1 or more.
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

    // Rotate only if the dealer team's total match score is at least +1.
    if (dealerTeamScore < 1) {
      return currentDealerIndex;
    }

    // New round: move one seat right-to-left around the table.
    return (currentDealerIndex - 1 + playerCount) % playerCount;
  }
}
