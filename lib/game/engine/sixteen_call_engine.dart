enum SixteenCallStatus {
  notCalled,
  inProgress,
  succeeded,
  failed,
}

class SixteenCallEngine {
  SixteenCallEngine({
    required this.playerCount,
    required this.biddingTeam,
    required this.bidAmount,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (biddingTeam != 0 && biddingTeam != 1) {
      throw ArgumentError('Team must be 0 or 1.');
    }

    if (bidAmount < 4 || bidAmount > 7) {
      throw ArgumentError(
        '16 Call is allowed only after bids 4 to 7.',
      );
    }
  }

  final int playerCount;
  final int biddingTeam;
  final int bidAmount;

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

  bool get canCall =>
      status == SixteenCallStatus.notCalled &&
      completedTricks == bidAmount &&
      completedTricks < 8 &&
      biddingTeamTricks == bidAmount &&
      lastTrickWinnerIndex != null &&
      (lastTrickWinnerIndex! % 2) == biddingTeam;

  void call16({required int callerPlayerIndex}) {
    if (status != SixteenCallStatus.notCalled) {
      throw StateError('16 Call has already been made.');
    }

    if (completedTricks != bidAmount || completedTricks >= 8) {
      throw StateError(
        '16 Call is available immediately after the bidding team wins its bid number of consecutive tricks.',
      );
    }

    if (biddingTeamTricks != bidAmount) {
      throw StateError(
        'Bidding team has not reached its bid.',
      );
    }

    if (callerPlayerIndex < 0 ||
        callerPlayerIndex >= playerCount) {
      throw ArgumentError('Invalid caller index.');
    }

    if (callerPlayerIndex != lastTrickWinnerIndex) {
      throw StateError(
        'Only the previous trick winner can call 16.',
      );
    }

    if (callerPlayerIndex % 2 != biddingTeam) {
      throw StateError(
        'Only a member of the bidding team can call 16.',
      );
    }

    callerIndex = callerPlayerIndex;
    status = SixteenCallStatus.inProgress;
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
