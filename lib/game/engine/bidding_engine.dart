enum BidAction { bid, pass }

class BidRecord {
  final int playerIndex;
  final BidAction action;
  final int? amount;

  const BidRecord({
    required this.playerIndex,
    required this.action,
    this.amount,
  });
}

class BiddingEngine {
  final int playerCount;
  final int dealerIndex;
  final List<BidRecord> history = [];

  int? highestBid;
  int? highestBidder;

  late int currentPlayerIndex;

  BiddingEngine({
    required this.playerCount,
    required this.dealerIndex,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex < 0 || dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }

    currentPlayerIndex = (dealerIndex + 1) % playerCount;
  }

  bool get isComplete => history.length == playerCount;

  bool get everyonePassed =>
      isComplete && highestBid == null;

  bool get hasWinner =>
      isComplete && highestBidder != null;

  int get remainingPlayers => playerCount - history.length;

  void submitBid(int? amount) {
    if (isComplete) {
      throw StateError('Bidding is already complete.');
    }

    if (amount != null) {
      if (amount < 4 || amount > 8) {
        throw ArgumentError('Bid must be between 4 and 8.');
      }

      if (highestBid != null && amount <= highestBid!) {
        throw ArgumentError('New bid must be higher.');
      }
    }

    history.add(
      BidRecord(
        playerIndex: currentPlayerIndex,
        action: amount == null ? BidAction.pass : BidAction.bid,
        amount: amount,
      ),
    );

    if (amount != null) {
      highestBid = amount;
      highestBidder = currentPlayerIndex;
    }

    if (!isComplete) {
      currentPlayerIndex =
          (currentPlayerIndex + 1) % playerCount;
    }
  }
}
