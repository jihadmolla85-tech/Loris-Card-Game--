import 'package:loris_card_game/game/models/loris_card.dart';

/// Resolves a game card to the matching original card-face artwork.
String lorisCardFaceAssetPath(Card card) {
  if (card.isLoris) return 'assets/Spades_Joker_Red.png';

  final suitName = switch (card.suit!) {
    Suit.clubs => 'Clubs',
    Suit.diamonds => 'Diamonds',
    Suit.hearts => 'Hearts',
    Suit.spades => 'Spades',
  };
  final rankName = switch (card.rank) {
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    14 => 'A',
    final rank => '$rank',
  };
  return 'assets/$suitName${'_'}$rankName.png';
}

/// Rank-two faces are the suit samples shown in the trump picker. They are
/// previews only; they do not add rank two to either playable deck.
String lorisTrumpPreviewCardAssetPath(Suit suit) {
  final suitName = switch (suit) {
    Suit.clubs => 'Clubs',
    Suit.diamonds => 'Diamonds',
    Suit.hearts => 'Hearts',
    Suit.spades => 'Spades',
  };
  return 'assets/${suitName}_2.png';
}
