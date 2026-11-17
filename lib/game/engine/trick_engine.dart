
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
  final Suit? trumpSuit;

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

    // A leading Joker has no suit to follow.
    return firstCard.isLoris ? null : firstCard.suit;
  }

  /// Returns every card the player is allowed to play on this turn.
  ///
  /// LORIS is always playable. Otherwise players must follow the led suit.
  /// If void in the led suit, they must trump when they hold a trump card.
  /// Whenever a trump has already been played, a higher trump must be used
  /// when the player is void in the led suit (or when trump itself was led)
  /// and such a higher trump is held.
  List<Card> legalCardsFor(int playerIndex) {
    if (isComplete) {
      throw StateError('Trick is already complete.');
    }
    if (playerIndex != currentPlayerIndex) {
      throw StateError('It is not this player’s turn.');
    }

    final hand = hands[playerIndex];
    final lorisCards = hand.where((card) => card.isLoris).toList();
    final currentLedSuit = ledSuit;

    if (currentLedSuit == null) {
      return List.unmodifiable(hand);
    }

    final ledSuitCards = hand
        .where((card) => !card.isLoris && card.suit == currentLedSuit)
        .toList();

    if (ledSuitCards.isNotEmpty) {
      // When trump was led, follow suit and overtrump if possible.
      if (trumpSuit != null && currentLedSuit == trumpSuit) {
        final highestTrump = _highestTrumpRankAlreadyPlayed();
        if (highestTrump != null && !plays.any((play) => play.card.isLoris)) {
          final higher = ledSuitCards
              .where((card) => (card.rank ?? 0) > highestTrump)
              .toList();
          if (higher.isNotEmpty) {
            return List.unmodifiable([...higher, ...lorisCards]);
          }
        }
      }
      return List.unmodifiable([...ledSuitCards, ...lorisCards]);
    }

    // In Joker mode there is no trump suit; follow suit when possible,
    // otherwise any card may be played.
    if (trumpSuit == null) return List.unmodifiable(hand);

    // The player is void in the led suit. Trump is compulsory when held.
    final trumps = hand
        .where((card) => !card.isLoris && card.suit == trumpSuit)
        .toList();
    if (trumps.isEmpty) {
      return List.unmodifiable(hand);
    }

    // LORIS is already unbeatable, so no ordinary trump can overtrump it.
    if (plays.any((play) => play.card.isLoris)) {
      return List.unmodifiable([...trumps, ...lorisCards]);
    }

    final highestTrump = _highestTrumpRankAlreadyPlayed();
    if (highestTrump != null) {
      final higher = trumps
          .where((card) => (card.rank ?? 0) > highestTrump)
          .toList();
      if (higher.isNotEmpty) {
        return List.unmodifiable([...higher, ...lorisCards]);
      }
    }

    return List.unmodifiable([...trumps, ...lorisCards]);
  }

  int? _highestTrumpRankAlreadyPlayed() {
    if (trumpSuit == null) return null;
    final ranks = plays
        .where((play) => !play.card.isLoris && play.card.suit == trumpSuit)
        .map((play) => play.card.rank ?? 0)
        .toList();
    if (ranks.isEmpty) return null;
    return ranks.reduce((a, b) => a > b ? a : b);
  }

  void playCard(int playerIndex, Card card) {
    final legalCards = legalCardsFor(playerIndex);
    if (!legalCards.contains(card)) {
      throw ArgumentError('This card cannot be played under LORIS rules.');
    }

    final hand = hands[playerIndex];
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

    if (trumpSuit == null) {
      // Joker mode: the Joker itself is unbeatable; otherwise compare
      // every card played, regardless of suit.
      return _highestRankPlay(plays).playerIndex;
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
