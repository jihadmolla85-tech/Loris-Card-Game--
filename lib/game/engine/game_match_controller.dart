
import 'dart:math';

import 'game_round_controller.dart';
import 'match_score_engine.dart';
import 'bid_scoring_engine.dart';
import 'deal_controller.dart';
import 'initial_dealer_selector.dart';
import 'sixteen_call_engine.dart';
import 'trick_engine.dart';
import 'game_state_snapshot.dart';
import 'game_save_service.dart';
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

  /// Randomly selects the starting seat.
  /// The first player to draw a Jack becomes the initial dealer.
  DealerSelectionResult selectInitialDealer({
    required List<Card> deck,
    required int playerCount,
    Random? random,
  }) {
    if (_currentRound != null) {
      throw StateError(
        'Initial dealer can only be selected before the first round.',
      );
    }

    return _selectDealerFromDraw(deck: deck, playerCount: playerCount, random: random);
  }

  DealerSelectionResult _selectDealerFromDraw({
    required List<Card> deck,
    required int playerCount,
    Random? random,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }
    if (deck.length != playerCount * 8) {
      throw ArgumentError('Invalid deck size.');
    }

    final rng = random ?? Random();
    final firstPlayerIndex = rng.nextInt(playerCount);
    final drawDeck = List<Card>.from(deck)..shuffle(rng);
    final result = InitialDealerSelector.select(
      deck: drawDeck,
      playerCount: playerCount,
      firstPlayerIndex: firstPlayerIndex,
      random: rng,
    );
    dealerIndex = result.dealerIndex;
    return result;
  }

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
      throw ArgumentError('Invalid dealer index for player count.');
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
      throw StateError('DealController has not been configured.');
    }

    if (isMatchOver) {
      throw StateError('The match has already ended.');
    }

    if (_currentRound != null &&
        !_currentRound!.isRoundEnded) {
      throw StateError('The current round has not ended.');
    }

    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index for player count.');
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
      throw StateError('DealController has not been configured.');
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

    final newHands = controller.redeal();

    _currentRound = null;
    _dealerAdvanced = false;

    return newHands;
  }

  void startRoundWithCurrentDeal({
    required Suit trumpSuit,
    required int biddingTeam,
    required int bidAmount,
  }) {
    final controller = dealController;

    if (controller == null) {
      throw StateError('DealController has not been configured.');
    }

    final hands = controller.currentHands;

    if (hands == null) {
      throw StateError('Deal has not started.');
    }

    startRound(
      hands: hands,
      trumpSuit: trumpSuit,
      biddingTeam: biddingTeam,
      bidAmount: bidAmount,
    );
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

  GameStateSnapshot createSnapshot() {
    final round = _currentRound;
    final controller = dealController;

    final hands = round?.trickEngine.hands ??
        controller?.currentHands ??
        <List<Card>>[];

    final sixteen = round?.sixteenCallEngine;
    final redeal = controller?.redealController.lastResult;

    return GameStateSnapshot(
      dealerIndex: dealerIndex,
      dealerAdvanced: _dealerAdvanced,
      teamAScore: matchScoreEngine.teamAScore,
      teamBScore: matchScoreEngine.teamBScore,
      playerCount: hands.isNotEmpty
          ? hands.length
          : controller?.playerCount,
      originalDeck: controller?.originalDeck ?? const [],
      hands: hands
          .map((hand) => List<Card>.from(hand))
          .toList(),
      trumpSuit: round?.trickEngine.trumpSuit,
      biddingTeam: round?.biddingTeam,
      bidAmount: round?.bidAmount,
      // A completed trick has already been scored. Do not serialize its
      // plays as an in-progress trick, otherwise restore rejects a full
      // trick (and a finished round cannot be resumed).
      trickPlays: round == null || round.trickEngine.isComplete
          ? const []
          : round.trickEngine.plays
              .map((play) => SnapshotTrickPlay(
                    playerIndex: play.playerIndex,
                    card: play.card,
                  ))
              .toList(),
      firstPlayerIndex: round?.trickEngine.firstPlayerIndex,
      completedTricks: round?.completedTricks ?? 0,
      biddingTeamTricks: round?.biddingTeamTricks ?? 0,
      isRoundScored: round?.isRoundScored ?? false,
      sixteenCallStatus: sixteen?.status.name ?? 'notCalled',
      sixteenCompletedTricks: sixteen?.completedTricks ?? 0,
      sixteenBiddingTeamTricks:
          sixteen?.biddingTeamTricks ?? 0,
      sixteenLastTrickWinnerIndex:
          sixteen?.lastTrickWinnerIndex,
      sixteenCallerIndex: sixteen?.callerIndex,
      sixteenBiddingTeamPoints:
          sixteen?.biddingTeamPoints ?? 0,
      sixteenOpposingTeamPoints:
          sixteen?.opposingTeamPoints ?? 0,
      redealShouldRedeal: redeal?.shouldRedeal ?? false,
      redealReasons: redeal?.reasons
              .map((reason) => reason.name)
              .toList() ??
          const [],
      redealDealerIndex: redeal?.sameDealerIndex,
    );
  }

  void restoreSnapshot(GameStateSnapshot snapshot) {
    if (snapshot.version != 1) {
      throw FormatException(
        'Unsupported save version: ${snapshot.version}',
      );
    }

    if (snapshot.dealerIndex < 0 ||
        snapshot.dealerIndex >= 6) {
      throw const FormatException('Invalid saved dealer index.');
    }

    dealerIndex = snapshot.dealerIndex;
    _dealerAdvanced = snapshot.dealerAdvanced;

    matchScoreEngine.teamAScore = snapshot.teamAScore;
    matchScoreEngine.teamBScore = snapshot.teamBScore;

    final controller = dealController;

    if (snapshot.playerCount != null &&
        snapshot.hands.isNotEmpty &&
        controller != null) {
      if (snapshot.originalDeck.isNotEmpty) {
        controller.restoreDeal(
          originalDeck: snapshot.originalDeck,
          hands: snapshot.hands,
          dealerIndex: snapshot.dealerIndex,
          playerCount: snapshot.playerCount!,
        );
      }

      if (snapshot.redealDealerIndex != null) {
        controller.redealController.restoreResult(
          shouldRedeal: snapshot.redealShouldRedeal,
          reasons: snapshot.redealReasons,
          dealerIndex: snapshot.redealDealerIndex!,
        );
      }
    }

    _currentRound = null;

    if (snapshot.hands.isEmpty ||
        snapshot.trumpSuit == null ||
        snapshot.biddingTeam == null ||
        snapshot.bidAmount == null) {
      return;
    }

    final restoredStatus = SixteenCallStatus.values.firstWhere(
      (status) => status.name == snapshot.sixteenCallStatus,
      orElse: () => SixteenCallStatus.notCalled,
    );

    final restoredPlays = snapshot.trickPlays
        .map((play) => TrickPlay(
              playerIndex: play.playerIndex,
              card: play.card,
            ))
        .toList();

    _currentRound = GameRoundController(
      hands: snapshot.hands
          .map((hand) => List<Card>.from(hand))
          .toList(),
      dealerIndex: snapshot.dealerIndex,
      trumpSuit: snapshot.trumpSuit!,
      biddingTeam: snapshot.biddingTeam!,
      bidAmount: snapshot.bidAmount!,
      matchScoreEngine: matchScoreEngine,
      bidScoringEngine: bidScoringEngine,
      restoredCompletedTricks: snapshot.completedTricks,
      restoredBiddingTeamTricks: snapshot.biddingTeamTricks,
      restoredIsRoundScored: snapshot.isRoundScored,
      initialTrickPlays: restoredPlays,
      restoredFirstPlayerIndex: snapshot.firstPlayerIndex,
      restoredSixteenCallStatus: restoredStatus,
      restoredSixteenCompletedTricks:
          snapshot.sixteenCompletedTricks,
      restoredSixteenBiddingTeamTricks:
          snapshot.sixteenBiddingTeamTricks,
      restoredSixteenLastTrickWinnerIndex:
          snapshot.sixteenLastTrickWinnerIndex,
      restoredSixteenCallerIndex:
          snapshot.sixteenCallerIndex,
      restoredSixteenBiddingTeamPoints:
          snapshot.sixteenBiddingTeamPoints,
      restoredSixteenOpposingTeamPoints:
          snapshot.sixteenOpposingTeamPoints,
    );
  }

  Future<void> saveGame(GameSaveService service) async {
    await service.save(createSnapshot());
  }

  Future<bool> resumeGame(GameSaveService service) async {
    final snapshot = await service.load();

    if (snapshot == null) {
      return false;
    }

    restoreSnapshot(snapshot);
    return true;
  }
}
