
enum MatchWinner {
  teamA,
  teamB,
  draw,
  none,
}

class MatchScoreEngine {
  static const int winningScore = 32;

  int teamAScore = 0;
  int teamBScore = 0;

  /// Applies points after a round has ended.
  MatchWinner applyRoundScore({
    required int teamAPoints,
    required int teamBPoints,
  }) {
    if (teamAPoints + teamBPoints != 0) {
      throw ArgumentError('Round scores must be zero-sum.');
    }

    teamAScore += teamAPoints;
    teamBScore += teamBPoints;

    return checkWinner();
  }

  /// Checks whether a team has reached the winning score.
  MatchWinner checkWinner() {
    final teamAReached = teamAScore >= winningScore;
    final teamBReached = teamBScore >= winningScore;

    if (teamAReached && teamBReached) {
      return MatchWinner.draw;
    }

    if (teamAReached) {
      return MatchWinner.teamA;
    }

    if (teamBReached) {
      return MatchWinner.teamB;
    }

    return MatchWinner.none;
  }

  void resetMatch() {
    teamAScore = 0;
    teamBScore = 0;
  }
}
