
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

    // In a suit-trump round, a leading LORIS follows the legacy Spades lead.
    return firstCard.isLoris ? Suit.spades : firstCard.suit;
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
      // Following the led suit remains mandatory, but players are never
      // forced to overtrump: any card of the led suit (or LORIS) is legal.
      return List.unmodifiable([...ledSuitCards, ...lorisCards]);
    }

    // If void in the led suit, the player may discard any card.
    // Trumping and overtrumping are optional in every suit-trump round.
    return List.unmodifiable(hand);
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
    final lorisLedAsOrdinarySpades =
        completedTricks == 7 && plays.first.card.isLoris;

    // LORIS is normally unbeatable. The sole exception is when it is
    // led on the eighth (final) trick: it then behaves as its replaced
    // low Spades card, and can be beaten by a higher Spade or a trump.
    if (lorisPlay != null && !lorisLedAsOrdinarySpades) {
      return lorisPlay.playerIndex;
    }

    final currentLedSuit = ledSuit;

    if (trumpSuit == null) {
      // Without a selected trump suit, only the led suit can win.
      final ledSuitPlays =
          plays.where((p) => _effectiveSuit(p) == currentLedSuit).toList();
      return _highestRankPlay(ledSuitPlays).playerIndex;
    }

    final trumpPlays =
        plays.where((p) => _effectiveSuit(p) == trumpSuit).toList();
    if (trumpPlays.isNotEmpty) {
      return _highestRankPlay(trumpPlays).playerIndex;
    }
    final ledSuitPlays =
        plays.where((p) => _effectiveSuit(p) == currentLedSuit).toList();
    return _highestRankPlay(ledSuitPlays).playerIndex;
  }

  Suit? _effectiveSuit(TrickPlay play) =>
      play.card.isLoris ? Suit.spades : play.card.suit;

  int _effectiveRank(TrickPlay play) =>
      play.card.isLoris ? (play.card.replacesRank ?? 0) : (play.card.rank ?? 0);

  TrickPlay _highestRankPlay(List<TrickPlay> candidates) {
    return candidates.reduce((a, b) {
      return _effectiveRank(b) > _effectiveRank(a) ? b : a;
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
