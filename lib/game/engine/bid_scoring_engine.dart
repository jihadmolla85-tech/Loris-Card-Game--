
class BidScoreResult {
  final bool success;
  final int biddingTeam;
  final int bidAmount;
  final int tricksWon;
  final int biddingTeamPoints;
  final int opposingTeamPoints;

  const BidScoreResult({
    required this.success,
    required this.biddingTeam,
    required this.bidAmount,
    required this.tricksWon,
    required this.biddingTeamPoints,
    required this.opposingTeamPoints,
  });
}

class BidScoringEngine {
  final List<int> teamScores = [0, 0];

  BidScoreResult calculate({
    required int biddingTeam,
    required int bidAmount,
    required int tricksWonByBiddingTeam,
  }) {
    if (biddingTeam != 0 && biddingTeam != 1) {
      throw ArgumentError('Team must be 0 or 1.');
    }

    if (bidAmount < 4 || bidAmount > 8) {
      throw ArgumentError('Bid must be between 4 and 8.');
    }

    if (tricksWonByBiddingTeam < 0 ||
        tricksWonByBiddingTeam > 8) {
      throw ArgumentError('Tricks must be between 0 and 8.');
    }

    final success = bidAmount == 8
        ? tricksWonByBiddingTeam == 8
        : tricksWonByBiddingTeam >= bidAmount;

    // A successful special 8 bid scores 16. Successful bids from 4 to 7
    // score exactly the bid amount, even if more tricks are won. A failed
    // bid awards the opposing team twice the bid amount.
    final points = success ? (bidAmount == 8 ? 16 : bidAmount) : bidAmount * 2;

    final biddingPoints = success ? points : -points;

    return BidScoreResult(
      success: success,
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
      tricksWon: tricksWonByBiddingTeam,
      biddingTeamPoints: biddingPoints,
      opposingTeamPoints: -biddingPoints,
    );
  }

  BidScoreResult calculateAndApply({
    required int biddingTeam,
    required int bidAmount,
    required int tricksWonByBiddingTeam,
  }) {
    final result = calculate(
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
      tricksWonByBiddingTeam: tricksWonByBiddingTeam,
    );

    teamScores[biddingTeam] += result.biddingTeamPoints;
    teamScores[1 - biddingTeam] += result.opposingTeamPoints;

    return result;
  }

  int get teamAScore => teamScores[0];
  int get teamBScore => teamScores[1];

  void resetScores() {
    teamScores[0] = 0;
    teamScores[1] = 0;
  }
}
