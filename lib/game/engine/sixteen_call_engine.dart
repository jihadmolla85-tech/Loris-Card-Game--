enum SixteenCallStatus {
  notCalled,
  passed,
  inProgress,
  succeeded,
  failed,
}

class SixteenCallEngine {
  SixteenCallEngine({
    required this.playerCount,
    required this.biddingTeam,
    required this.bidAmount,
    this.biddingTeamScore = 0,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }
    if (biddingTeam != 0 && biddingTeam != 1) {
      throw ArgumentError('Team must be 0 or 1.');
    }
    if (bidAmount < 4 || bidAmount > 7) {
      throw ArgumentError('16 Call is allowed only after bids 4 to 7.');
    }
  }

  final int playerCount;
  final int biddingTeam;
  final int bidAmount;
  final int biddingTeamScore;

  int completedTricks = 0;
  int biddingTeamTricks = 0;
  int? lastTrickWinnerIndex;
  int? callerIndex;

  SixteenCallStatus status = SixteenCallStatus.notCalled;
  int biddingTeamPoints = 0;
  int opposingTeamPoints = 0;

  bool get isRoundEnded =>
      completedTricks == 8 ||
      status == SixteenCallStatus.failed ||
      status == SixteenCallStatus.succeeded;

  // Since completedTricks must equal bidAmount and the bidding team must
  // have won every one of them, this only opens after a consecutive streak.
  bool get canCall =>
      status == SixteenCallStatus.notCalled &&
      biddingTeamScore < 16 &&
      completedTricks == bidAmount &&
      completedTricks < 8 &&
      biddingTeamTricks == bidAmount &&
      lastTrickWinnerIndex != null &&
      (lastTrickWinnerIndex! % 2) == biddingTeam;

  void _validateDecision({required int callerPlayerIndex}) {
    if (!canCall) {
      throw StateError('16 Call decision is not available.');
    }
    if (callerPlayerIndex < 0 || callerPlayerIndex >= playerCount) {
      throw ArgumentError('Invalid caller index.');
    }
    if (callerPlayerIndex != lastTrickWinnerIndex) {
      throw StateError('Only the previous trick winner can decide.');
    }
    if (callerPlayerIndex % 2 != biddingTeam) {
      throw StateError('Only a member of the bidding team can decide.');
    }
  }

  void call16({required int callerPlayerIndex}) {
    _validateDecision(callerPlayerIndex: callerPlayerIndex);
    callerIndex = callerPlayerIndex;
    status = SixteenCallStatus.inProgress;
  }

  void pass16({required int callerPlayerIndex}) {
    _validateDecision(callerPlayerIndex: callerPlayerIndex);
    callerIndex = callerPlayerIndex;
    status = SixteenCallStatus.passed;
  }

  SixteenCallStatus recordTrickWinner(int winnerIndex) {
    if (isRoundEnded) {
      throw StateError('The round has already ended.');
    }
    if (winnerIndex < 0 || winnerIndex >= playerCount) {
      throw ArgumentError('Invalid winner index.');
    }

    completedTricks++;
    lastTrickWinnerIndex = winnerIndex;
    final winnerTeam = winnerIndex % 2;
    if (winnerTeam == biddingTeam) {
      biddingTeamTricks++;
    }

    if (status == SixteenCallStatus.inProgress) {
      if (winnerTeam != biddingTeam) {
        status = SixteenCallStatus.failed;
        biddingTeamPoints = -16;
        opposingTeamPoints = 16;
      } else if (completedTricks == 8) {
        status = SixteenCallStatus.succeeded;
        biddingTeamPoints = 16;
        opposingTeamPoints = -16;
      }
    }
    return status;
  }
}
