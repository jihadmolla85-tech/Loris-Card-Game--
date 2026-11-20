import 'trick_engine.dart';
import 'sixteen_call_engine.dart';
import 'bid_scoring_engine.dart';
import 'match_score_engine.dart';
import 'dealer_rotation_engine.dart';
import '../models/loris_card.dart';

class GameRoundController {
  GameRoundController({
    required List<List<Card>> hands,
    required this.dealerIndex,
    required Suit? trumpSuit,
    required this.biddingTeam,
    required this.bidAmount,
    required this.matchScoreEngine,
    required this.bidScoringEngine,
    int restoredCompletedTricks = 0,
    int restoredBiddingTeamTricks = 0,
    bool restoredIsRoundScored = false,
    List<TrickPlay> initialTrickPlays = const [],
    int? restoredFirstPlayerIndex,
    SixteenCallStatus restoredSixteenCallStatus =
        SixteenCallStatus.notCalled,
    int restoredSixteenCompletedTricks = 0,
    int restoredSixteenBiddingTeamTricks = 0,
    int? restoredSixteenLastTrickWinnerIndex,
    int? restoredSixteenCallerIndex,
    int restoredSixteenBiddingTeamPoints = 0,
    int restoredSixteenOpposingTeamPoints = 0,
  }) {
    if (hands.length != 4 && hands.length != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex < 0 || dealerIndex >= hands.length) {
      throw ArgumentError('Invalid dealer index.');
    }

    if (biddingTeam != 0 && biddingTeam != 1) {
      throw ArgumentError('Team must be 0 or 1.');
    }

    if (bidAmount < 4 || bidAmount > 8) {
      throw ArgumentError('Bid must be between 4 and 8.');
    }

    if (restoredCompletedTricks < 0 ||
        restoredCompletedTricks > 8) {
      throw ArgumentError('Invalid completed tricks count.');
    }

    if (restoredBiddingTeamTricks < 0 ||
        restoredBiddingTeamTricks > 8) {
      throw ArgumentError('Invalid bidding team tricks count.');
    }

    trickEngine = TrickEngine(
      hands: hands,
      dealerIndex: dealerIndex,
      trumpSuit: trumpSuit,
      completedTricks: restoredCompletedTricks,
      initialPlays: initialTrickPlays,
      restoredFirstPlayerIndex: restoredFirstPlayerIndex,
    );

    sixteenCallEngine = bidAmount < 8
        ? SixteenCallEngine(
            playerCount: hands.length,
            biddingTeam: biddingTeam,
            bidAmount: bidAmount,
            biddingTeamScore: biddingTeam == 0
                ? matchScoreEngine.teamAScore
                : matchScoreEngine.teamBScore,
          )
        : null;

    completedTricks = restoredCompletedTricks;
    biddingTeamTricks = restoredBiddingTeamTricks;
    isRoundScored = restoredIsRoundScored;

    final sixteenEngine = sixteenCallEngine;

    if (sixteenEngine != null) {
      sixteenEngine.status = restoredSixteenCallStatus;
      sixteenEngine.completedTricks =
          restoredSixteenCompletedTricks;
      sixteenEngine.biddingTeamTricks =
          restoredSixteenBiddingTeamTricks;
      sixteenEngine.lastTrickWinnerIndex =
          restoredSixteenLastTrickWinnerIndex;
      sixteenEngine.callerIndex = restoredSixteenCallerIndex;
      sixteenEngine.biddingTeamPoints =
          restoredSixteenBiddingTeamPoints;
      sixteenEngine.opposingTeamPoints =
          restoredSixteenOpposingTeamPoints;
    }
  }

  final int dealerIndex;
  final int biddingTeam;
  final int bidAmount;
  final MatchScoreEngine matchScoreEngine;
  final BidScoringEngine bidScoringEngine;

  late final TrickEngine trickEngine;
  late final SixteenCallEngine? sixteenCallEngine;

  int completedTricks = 0;
  int biddingTeamTricks = 0;

  bool isRoundScored = false;

  int? get nextPlayerIndex =>
      isRoundEnded ? null : trickEngine.currentPlayerIndex;

  bool get isRoundEnded =>
      isRoundScored ||
      (sixteenCallEngine?.isRoundEnded ?? completedTricks == 8);

  MatchWinner get matchWinner =>
      matchScoreEngine.checkWinner();

  void playCard(int playerIndex, Card card) {
    if (sixteenCallEngine?.canCall == true) {
      throw StateError('Resolve the CALL 16 decision before the next trick.');
    }
    if (isRoundEnded) {
      throw StateError('The round has ended.');
    }

    trickEngine.playCard(playerIndex, card);
  }

  int completeTrick() {
    if (isRoundEnded) {
      throw StateError('The round has ended.');
    }

    if (!trickEngine.isComplete) {
      throw StateError('Trick is not complete.');
    }

    final winnerIndex = trickEngine.winnerIndex;

    completedTricks++;

    if (winnerIndex % 2 == biddingTeam) {
      biddingTeamTricks++;
    }

    sixteenCallEngine?.recordTrickWinner(winnerIndex);

    if (isRoundEnded) {
      _applyRoundScore();
    } else {
      trickEngine.resetTrick(nextLeaderIndex: winnerIndex);
    }

    return winnerIndex;
  }

  void call16({
    required int callerPlayerIndex,
  }) {
    if (isRoundEnded) {
      throw StateError('The round has ended.');
    }

    final engine = sixteenCallEngine;

    if (engine == null) {
      throw StateError('16 Call is not allowed on an 8 bid.');
    }

    engine.call16(
      callerPlayerIndex: callerPlayerIndex,
    );
  }

  void pass16({required int callerPlayerIndex}) {
    if (isRoundEnded) {
      throw StateError('The round has ended.');
    }
    final engine = sixteenCallEngine;
    if (engine == null) {
      throw StateError('16 Call is not allowed on an 8 bid.');
    }
    engine.pass16(callerPlayerIndex: callerPlayerIndex);
  }

  /// Whether the ordinary bid result is already mathematically decided
  /// and no 16-call decision or attempt can still change the result.
  bool get canSkipRemainingTricks {
    if (isRoundEnded) return false;
    final sixteen = sixteenCallEngine;
    if (sixteen?.status == SixteenCallStatus.inProgress ||
        sixteen?.canCall == true) {
      return false;
    }

    final opposingTeamTricks = completedTricks - biddingTeamTricks;
    if (bidAmount == 8) {
      // An 8 bid fails as soon as the bidding team loses any trick.
      return opposingTeamTricks > 0;
    }

    final opposingTarget = 8 - bidAmount + 1;
    return biddingTeamTricks >= bidAmount ||
        opposingTeamTricks >= opposingTarget;
  }

  /// Ends the round early only after its ordinary bid outcome is certain.
  void skipRemainingTricks() {
    if (!canSkipRemainingTricks) {
      throw StateError('The remaining tricks cannot be skipped yet.');
    }
    _applyRoundScore();
  }

  void _applyRoundScore() {
    if (isRoundScored) return;

    int teamAPoints;
    int teamBPoints;

    final engine = sixteenCallEngine;

    if (engine != null &&
        (engine.status == SixteenCallStatus.succeeded ||
            engine.status == SixteenCallStatus.failed)) {
      teamAPoints = biddingTeam == 0
          ? engine.biddingTeamPoints
          : engine.opposingTeamPoints;

      teamBPoints = -teamAPoints;
    } else {
      final result = bidScoringEngine.calculate(
        biddingTeam: biddingTeam,
        bidAmount: bidAmount,
        tricksWonByBiddingTeam: biddingTeamTricks,
      );

      teamAPoints = result.biddingTeam == 0
          ? result.biddingTeamPoints
          : result.opposingTeamPoints;

      teamBPoints = -teamAPoints;
    }

    matchScoreEngine.applyRoundScore(
      teamAPoints: teamAPoints,
      teamBPoints: teamBPoints,
    );

    isRoundScored = true;
  }

  int getNextDealerIndex({bool isRedeal = false}) {
    final dealerTeam = dealerIndex % 2;
    final dealerTeamTotalScore = dealerTeam == 0
        ? matchScoreEngine.teamAScore
        : matchScoreEngine.teamBScore;

    return DealerRotationEngine.nextDealerIndex(
      currentDealerIndex: dealerIndex,
      playerCount: trickEngine.playerCount,
      dealerTeamScore: dealerTeamTotalScore,
      isRedeal: isRedeal,
    );
  }
}
