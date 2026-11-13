class TrickScoringEngine {
  final int playerCount;

  final List<int> playerTricks;
  final List<int> teamScores = [0, 0];

  TrickScoringEngine({
    required this.playerCount,
  }) : playerTricks = List.filled(playerCount, 0) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError(
        'Player count must be 4 or 6.',
      );
    }
  }

  int get totalTricks =>
      playerTricks.fold(0, (sum, value) => sum + value);

  int get teamATricks =>
      playerTricks
          .asMap()
          .entries
          .where((entry) => entry.key.isEven)
          .fold(0, (sum, entry) => sum + entry.value);

  int get teamBTricks =>
      playerTricks
          .asMap()
          .entries
          .where((entry) => entry.key.isOdd)
          .fold(0, (sum, entry) => sum + entry.value);

  bool get isRoundComplete => totalTricks == 8;

  void recordTrickWinner(int winnerIndex) {
    if (isRoundComplete) {
      throw StateError(
        'All 8 tricks have already been recorded.',
      );
    }

    if (winnerIndex < 0 || winnerIndex >= playerCount) {
      throw ArgumentError('Invalid winner index.');
    }

    playerTricks[winnerIndex]++;

    final teamIndex = winnerIndex.isEven ? 0 : 1;
    teamScores[teamIndex]++;
  }

  int get teamAScore => teamScores[0];

  int get teamBScore => teamScores[1];

  void resetRound() {
    for (var i = 0; i < playerCount; i++) {
      playerTricks[i] = 0;
    }

    teamScores[0] = 0;
    teamScores[1] = 0;
  }
}
