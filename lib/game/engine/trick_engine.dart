
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

  late int _firstPlayerIndex;

  TrickEngine({
    required this.hands,
    required this.dealerIndex,
    required this.trumpSuit,
    this.completedTricks = 0,
    List<TrickPlay> initialPlays = const [],
    int? restoredFirstPlayerIndex,
  }) : playerCount = hands.length {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex < 0 || dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }

    if (completedTricks < 0 || completedTricks > 8) {
      throw ArgumentError('Invalid completed trick count.');
    }

    _firstPlayerIndex =
        restoredFirstPlayerIndex ?? (dealerIndex + 1) % playerCount;

    if (_firstPlayerIndex < 0 || _firstPlayerIndex >= playerCount) {
      throw ArgumentError('Invalid first player index.');
    }

    if (initialPlays.length >= playerCount) {
      throw ArgumentError('Invalid initial trick plays.');
    }

    final playedByPlayers = <int>{};

    for (var i = 0; i < initialPlays.length; i++) {
      final play = initialPlays[i];
      final expectedPlayer =
          (_firstPlayerIndex + i) % playerCount;

      if (play.playerIndex != expectedPlayer) {
        throw ArgumentError('Invalid restored trick play order.');
      }

      if (!playedByPlayers.add(play.playerIndex)) {
        throw ArgumentError('A player cannot play twice in one trick.');
      }
    }

    for (var i = 0; i < playerCount; i++) {
      final expectedHandSize =
          8 - completedTricks - (playedByPlayers.contains(i) ? 1 : 0);

      if (hands[i].length != expectedHandSize) {
        throw ArgumentError('Invalid hand size for player $i.');
      }
    }

    plays.addAll(initialPlays);
  }

  int get firstPlayerIndex => _firstPlayerIndex;

  int get currentPlayerIndex =>
      (_firstPlayerIndex + plays.length) % playerCount;

  bool get isComplete => plays.length == playerCount;

  Suit? get ledSuit {
    if (plays.isEmpty) return null;

    final firstCard = plays.first.card;

    // LORIS প্রথমে খেললে Spades স্যুট ধরা হবে।
    return firstCard.isLoris ? Suit.spades : firstCard.suit;
  }

  void playCard(int playerIndex, Card card) {
    if (isComplete) {
      throw StateError('Trick is already complete.');
    }

    if (playerIndex != currentPlayerIndex) {
      throw StateError('It is not this player’s turn.');
    }

    final hand = hands[playerIndex];

    if (!hand.contains(card)) {
      throw ArgumentError('Card is not in this player’s hand.');
    }

    final currentLedSuit = ledSuit;

    // LORIS যেকোনো সময় খেলা যাবে।
    // অন্য কার্ড খেললে হাতে led suit থাকলে সেটি অনুসরণ করতে হবে।
    if (currentLedSuit != null && !card.isLoris) {
      final hasLedSuit = hand.any(
        (heldCard) =>
            !heldCard.isLoris &&
            heldCard.suit == currentLedSuit,
      );

      if (hasLedSuit && card.suit != currentLedSuit) {
        throw ArgumentError('You must follow the led suit.');
      }
    }

    hand.remove(card);
    plays.add(TrickPlay(playerIndex: playerIndex, card: card));
  }

  int get winnerIndex {
    if (!isComplete) {
      throw StateError('Trick is not complete.');
    }

    final lorisPlay = plays.where((p) => p.card.isLoris).firstOrNull;

    if (lorisPlay != null) {
      return lorisPlay.playerIndex;
    }

    final currentLedSuit = ledSuit;

    final trumpPlays =
        plays.where((p) => p.card.suit == trumpSuit).toList();

    if (trumpPlays.isNotEmpty) {
      return _highestRankPlay(trumpPlays).playerIndex;
    }

    final ledSuitPlays =
        plays.where((p) => p.card.suit == currentLedSuit).toList();

    return _highestRankPlay(ledSuitPlays).playerIndex;
  }

  TrickPlay _highestRankPlay(List<TrickPlay> candidates) {
    return candidates.reduce((a, b) {
      final aRank = a.card.rank ?? 0;
      final bRank = b.card.rank ?? 0;
      return bRank > aRank ? b : a;
    });
  }

  void resetTrick({int? nextLeaderIndex}) {
    if (!isComplete) {
      throw StateError('Cannot reset an incomplete trick.');
    }

    final leader = nextLeaderIndex ?? winnerIndex;

    if (leader < 0 || leader >= playerCount) {
      throw ArgumentError('Invalid next leader index.');
    }

    completedTricks++;
    _firstPlayerIndex = leader;
    plays.clear();
  }
}
