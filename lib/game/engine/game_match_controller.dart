
import 'game_round_controller.dart';
import 'match_score_engine.dart';
import 'bid_scoring_engine.dart';
import 'deal_controller.dart';
import 'redeal_validation_engine.dart';
import '../models/loris_card.dart';

class GameMatchController {
  GameMatchController({
    required int initialDealerIndex,
    required this.matchScoreEngine,
    required this.bidScoringEngine,
    this.dealController,
  }) : dealerIndex = initialDealerIndex {
    if (initialDealerIndex < 0 || initialDealerIndex >= 6) {
      throw ArgumentError('Invalid initial dealer index.');
    }
  }

  int dealerIndex;

  final MatchScoreEngine matchScoreEngine;
  final BidScoringEngine bidScoringEngine;
  final DealController? dealController;

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

    if (dealerIndex >= hands.length) {
      throw ArgumentError(
        'Invalid dealer index for player count.',
      );
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

  List<List<Card>> startRoundWithDeal({
    required List<Card> deck,
    required int playerCount,
    required Suit trumpSuit,
    required int biddingTeam,
    required int bidAmount,
  }) {
    final controller = dealController;

    if (controller == null) {
      throw StateError(
        'DealController has not been configured.',
      );
    }

    if (isMatchOver) {
      throw StateError('The match has already ended.');
    }

    if (_currentRound != null &&
        !_currentRound!.isRoundEnded) {
      throw StateError(
        'The current round has not ended.',
      );
    }

    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex >= playerCount) {
      throw ArgumentError(
        'Invalid dealer index for player count.',
      );
    }

    final hands = controller.deal(
      deck: deck,
      playerCount: playerCount,
      dealerIndex: dealerIndex,
    );

    startRound(
      hands: hands,
      trumpSuit: trumpSuit,
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
    );

    return hands;
  }

  List<List<Card>> validateAndRedeal({
    required bool everyonePassed,
    required bool bidderHasTrumpSuit,
  }) {
    final controller = dealController;

    if (controller == null) {
      throw StateError(
        'DealController has not been configured.',
      );
    }

    final hands = controller.currentHands;

    if (hands == null) {
      throw StateError('Deal has not started.');
    }

    final result = controller.validateDeal(
      everyonePassed: everyonePassed,
      bidderHasTrumpSuit: bidderHasTrumpSuit,
    );

    if (!result.shouldRedeal) {
      return hands;
    }

    if (result.sameDealerIndex != dealerIndex) {
      throw StateError('Redeal dealer does not match.');
    }

    return controller.redeal();
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
