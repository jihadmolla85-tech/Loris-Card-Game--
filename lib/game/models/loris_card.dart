enum Suit { clubs, diamonds, hearts, spades }

enum PlayerCount {
  four(4),
  six(6);

  const PlayerCount(this.value);
  final int value;
}

class Card {
  final Suit? suit;
  final int? rank;
  final bool isLoris;
  final int? replacesRank;

  const Card.normal({
    required Suit this.suit,
    required int this.rank,
  })  : isLoris = false,
        replacesRank = null,
        assert(rank >= 3 && rank <= 14);

  const Card.loris({required this.replacesRank})
      : suit = null,
        rank = null,
        isLoris = true;

  String get displayName {
    if (isLoris) return 'JOKER';
    const names = {
      11: 'J',
      12: 'Q',
      13: 'K',
      14: 'A',
    };
    return names[rank] ?? '$rank';
  }

  @override
  bool operator ==(Object other) =>
      other is Card &&
      other.suit == suit &&
      other.rank == rank &&
      other.isLoris == isLoris &&
      other.replacesRank == replacesRank;

  @override
  int get hashCode =>
      Object.hash(suit, rank, isLoris, replacesRank);

  @override
  String toString() =>
      isLoris ? 'JOKER' : '${displayName}_${suit!.name}';
}
