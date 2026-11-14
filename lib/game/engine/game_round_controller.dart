
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
    required Suit trumpSuit,
    required this.biddingTeam,
    required this.bidAmount,
    required this.matchScoreEngine,
    required this.bidScoringEngine,
  }) {
    trickEngine = TrickEngine(
      hands: hands,
      dealerIndex: dealerIndex,
      trumpSuit: trumpSuit,
    );

    sixteenCallEngine = SixteenCallEngine(
      playerCount: hands.length,
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
    );
  }

  final int dealerIndex;
  final int biddingTeam;

  final MatchScoreEngine matchScoreEngine;
  final BidScoringEngine bidScoringEngine;

  late final TrickEngine trickEngine;
  late final SixteenCallEngine sixteenCallEngine;

  bool isRoundScored = false;

  int? get nextPlayerIndex =>
      isRoundEnded ? null : trickEngine.currentPlayerIndex;

  bool get isRoundEnded =>
      isRoundScored || sixteenCallEngine.isRoundEnded;

  MatchWinner get matchWinner =>
      matchScoreEngine.checkWinner();

  void playCard(int playerIndex, Card card) {
    if (isRoundEnded) {
      throw StateError('The round has ended.');
    }

    trickEngine.playCard(playerIndex, card);
  }

  int completeTrick() {
    if (!trickEngine.isComplete) {
      throw StateError('Trick is not complete.');
    }

    final winnerIndex = trickEngine.winnerIndex;

    sixteenCallEngine.recordTrickWinner(winnerIndex);

    if (sixteenCallEngine.isRoundEnded) {
      _applyRoundScore();
    } else {
      trickEngine.resetTrick();
    }

    return winnerIndex;
  }

  void call16({
    required int callerPlayerIndex,
  }) {
    if (isRoundEnded) {
      throw StateError('The round has ended.');
    }

    sixteenCallEngine.call16(
      callerPlayerIndex: callerPlayerIndex,
    );
  }

  void _applyRoundScore() {
    if (isRoundScored) return;

    int teamAPoints;
    int teamBPoints;

    if (sixteenCallEngine.status ==
            SixteenCallStatus.succeeded ||
        sixteenCallEngine.status ==
            SixteenCallStatus.failed) {
      teamAPoints = biddingTeam == 0
          ? sixteenCallEngine.biddingTeamPoints
          : sixteenCallEngine.opposingTeamPoints;

      teamBPoints = -teamAPoints;
    } else {
      final result = bidScoringEngine.calculateAndApply(
        biddingTeam: biddingTeam,
        bidAmount: bidAmount,
        tricksWonByBiddingTeam:
            sixteenCallEngine.biddingTeamTricks,
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

    final dealerTeamScore = dealerTeam == 0
        ? matchScoreEngine.teamAScore
        : matchScoreEngine.teamBScore;

    return DealerRotationEngine.nextDealerIndex(
      currentDealerIndex: dealerIndex,
      playerCount: trickEngine.playerCount,
      dealerTeamScore: dealerTeamScore,
      isRedeal: isRedeal,
    );
  }
}
