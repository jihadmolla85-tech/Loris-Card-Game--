
import '../ai/ai_bidding_strategy.dart';
import '../models/loris_card.dart';
import 'bidding_engine.dart';

class BiddingRoundController {
  BiddingRoundController({
    required this.hands,
    required int dealerIndex,
    this.humanPlayerIndex = 0,
    this.strategy = const AiBiddingStrategy(),
  }) : engine = BiddingEngine(
          playerCount: hands.length,
          dealerIndex: dealerIndex,
        ) {
    if (hands.length != 4 && hands.length != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (hands.any((hand) => hand.length != 8)) {
      throw ArgumentError('Each player must have 8 cards.');
    }

    if (humanPlayerIndex < 0 ||
        humanPlayerIndex >= hands.length) {
      throw ArgumentError('Invalid human player index.');
    }

  }

  final List<List<Card>> hands;
  final int humanPlayerIndex;
  final AiBiddingStrategy strategy;
  final BiddingEngine engine;

  bool get isComplete => engine.isComplete;

  bool get isHumanTurn =>
      !engine.isComplete &&
      engine.currentPlayerIndex == humanPlayerIndex;

  bool get isAiTurn =>
      !engine.isComplete &&
      engine.currentPlayerIndex != humanPlayerIndex;

  bool get everyonePassed => engine.everyonePassed;

  int? get highestBid => engine.highestBid;

  int? get highestBidder => engine.highestBidder;

  List<BidRecord> get history =>
      List.unmodifiable(engine.history);

  void submitHumanBid(int? amount) {
    if (!isHumanTurn) {
      throw StateError('It is not the human player turn.');
    }

    engine.submitBid(amount);
  }

  /// Resolves exactly one AI turn so the UI can animate its thinking and bid.
  BidRecord submitNextAiBid() {
    if (!isAiTurn) {
      throw StateError('It is not an AI player turn.');
    }

    final playerIndex = engine.currentPlayerIndex;
    final decision = strategy.chooseBid(
      hand: hands[playerIndex],
      playerIndex: playerIndex,
      highestBid: engine.highestBid,
      highestBidder: engine.highestBidder,
    );

    engine.submitBid(decision.bidAmount);
    return engine.history.last;
  }
}
