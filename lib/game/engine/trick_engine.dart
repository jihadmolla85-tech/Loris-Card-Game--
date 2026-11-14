
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

  int completedTricks;

  TrickEngine({
    required this.hands,
    required this.dealerIndex,
    required this.trumpSuit,
    int completedTricks = 0,
    List<TrickPlay> initialPlays = const [],
  })  : playerCount = hands.length,
        completedTricks = completedTricks {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex < 0 || dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }

    if (completedTricks < 0 || completedTricks > 8) {
      throw ArgumentError('Invalid completed tricks count.');
    }

    if (initialPlays.length >= playerCount) {
      throw ArgumentError('Invalid saved trick plays.');
    }

    final playedByPlayers = <int>{};

    for (var i = 0; i < initialPlays.length; i++) {
      final play = initialPlays[i];
      final expectedPlayer = (dealerIndex + 1 + i) % playerCount;

      if (play.playerIndex != expectedPlayer ||
          !playedByPlayers.add(play.playerIndex)) {
        throw ArgumentError('Invalid saved trick play order.');
      }
    }

    for (var i = 0; i < playerCount; i++) {
      final expectedCards =
          8 - completedTricks - (playedByPlayers.contains(i) ? 1 : 0);

      if (hands[i].length != expectedCards) {
        throw ArgumentError('Invalid saved hand for player $i.');
      }
    }

    plays.addAll(initialPlays);
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
