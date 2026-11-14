
import 'game_round_controller.dart';
import 'match_score_engine.dart';
import 'bid_scoring_engine.dart';
import '../models/loris_card.dart';

class GameMatchController {
  GameMatchController({
    required int initialDealerIndex,
    required this.matchScoreEngine,
    required this.bidScoringEngine,
  }) : dealerIndex = initialDealerIndex {
    if (initialDealerIndex < 0 || initialDealerIndex >= 6) {
      throw ArgumentError('Invalid initial dealer index.');
    }
  }

  int dealerIndex;

  final MatchScoreEngine matchScoreEngine;
  final BidScoringEngine bidScoringEngine;

  GameRoundController? _currentRound;
  bool _dealerAdvanced = false;

  GameRoundController get currentRound {
    final round = _currentRound;

    if (round == null) {
      throw StateError('No round has started.');
    }

    return round;
  }

  bool get hasStarted => _currentRound != null;

  bool get isMatchOver =>
      matchScoreEngine.checkWinner() != MatchWinner.none;

  MatchWinner get matchWinner =>
      matchScoreEngine.checkWinner();

  int? get nextPlayerIndex =>
      _currentRound?.nextPlayerIndex;

  void startRound({
    required List<List<Card>> hands,
    required Suit trumpSuit,
    required int biddingTeam,
    required int bidAmount,
  }) {
    if (isMatchOver) {
      throw StateError('The match has already ended.');
    }

    if (_currentRound != null &&
        !_currentRound!.isRoundEnded) {
      throw StateError('The current round has not ended.');
    }

    if (hands.length != 4 && hands.length != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    _currentRound = GameRoundController(
      hands: hands,
      dealerIndex: dealerIndex,
      trumpSuit: trumpSuit,
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
      matchScoreEngine: matchScoreEngine,
      bidScoringEngine: bidScoringEngine,
    );

    _dealerAdvanced = false;
  }

  void playCard(int playerIndex, Card card) {
    currentRound.playCard(playerIndex, card);
  }

  void call16({
    required int callerPlayerIndex,
  }) {
    currentRound.call16(
      callerPlayerIndex: callerPlayerIndex,
    );
  }

  int completeTrick() {
    final round = currentRound;

    final winnerIndex = round.completeTrick();

    if (round.isRoundEnded && !_dealerAdvanced) {
      dealerIndex = round.getNextDealerIndex();
      _dealerAdvanced = true;
    }

    return winnerIndex;
  }
}
