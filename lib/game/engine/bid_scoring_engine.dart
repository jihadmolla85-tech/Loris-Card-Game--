
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

    final points = success
        ? (bidAmount == 8 ? 16 : bidAmount)
        : bidAmount * 2;

    final biddingPoints = success ? points : -points;
    final opposingPoints = -biddingPoints;

    return BidScoreResult(
      success: success,
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
      tricksWon: tricksWonByBiddingTeam,
      biddingTeamPoints: biddingPoints,
      opposingTeamPoints: opposingPoints,
    );
  }
}
