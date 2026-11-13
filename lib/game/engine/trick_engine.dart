import '../models/loris_card.dart';

class TrickPlay {
  final int playerIndex;
  final Card card;

  const TrickPlay({
    required this.playerIndex,
    required this.card,
  });
}

class TrickEngine {
  final List<List<Card>> hands;
  final int playerCount;
  final int dealerIndex;
  final Suit trumpSuit;

  final List<TrickPlay> plays = [];

  int completedTricks = 0;

  TrickEngine({
    required this.hands,
    required this.dealerIndex,
    required this.trumpSuit,
  }) : playerCount = hands.length {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (hands.any((hand) => hand.length != 8)) {
      throw ArgumentError('Each player must start with 8 cards.');
    }

    if (dealerIndex < 0 || dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }
  }

  int get firstPlayerIndex =>
      (dealerIndex + 1) % playerCount;

  int get currentPlayerIndex =>
      (firstPlayerIndex + plays.length) % playerCount;

  bool get isComplete =>
      plays.length == playerCount;

  Suit get ledSuit {
    if (plays.isEmpty) {
      throw StateError('No card has been played.');
    }

    final firstCard = plays.first.card;

    // LORIS as the first card means Spades is led.
    if (firstCard.isLoris) {
      return Suit.spades;
    }

    return firstCard.suit!;
  }

  void playCard(int playerIndex, Card card) {
    if (isComplete) {
      throw StateError('Trick is already complete.');
    }

    if (playerIndex != currentPlayerIndex) {
      throw StateError('It is not this player turn.');
    }

    final hand = hands[playerIndex];

    if (!hand.contains(card)) {
      throw ArgumentError('Card is not in player hand.');
    }

    if (plays.isNotEmpty && !card.isLoris) {
      final requiredSuit = ledSuit;

      final hasLedSuit = hand.any(
        (c) => !c.isLoris && c.suit == requiredSuit,
      );

      if (hasLedSuit && card.suit != requiredSuit) {
        throw ArgumentError(
          'You must follow the led suit.',
        );
      }
    }

    hand.remove(card);

    plays.add(
      TrickPlay(
        playerIndex: playerIndex,
        card: card,
      ),
    );
  }

  int get winnerIndex {
    if (!isComplete) {
      throw StateError('Trick is not complete yet.');
    }

    // LORIS always wins.
    for (final play in plays) {
      if (play.card.isLoris) {
        return play.playerIndex;
      }
    }

    final trumpPlays = plays.where(
      (play) => play.card.suit == trumpSuit,
    ).toList();

    final candidates = trumpPlays.isNotEmpty
        ? trumpPlays
        : plays.where(
            (play) => play.card.suit == ledSuit,
          ).toList();

    candidates.sort(
      (a, b) => b.card.rank!.compareTo(a.card.rank!),
    );

    return candidates.first.playerIndex;
  }

  // Start the next trick without restoring played cards.
  void resetTrick() {
    if (!isComplete) {
      throw StateError(
        'Cannot reset before trick is complete.',
      );
    }

    completedTricks++;
    plays.clear();
  }
}
