import '../models/loris_card.dart';

class CardDealer {
  static List<List<Card>> deal({
    required List<Card> deck,
    required int playerCount,
    required int firstPlayerIndex,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (deck.length != playerCount * 8) {
      throw ArgumentError('Deck must contain 8 cards per player.');
    }

    if (firstPlayerIndex < 0 || firstPlayerIndex >= playerCount) {
      throw ArgumentError('Invalid first player index.');
    }

    final hands = List.generate(playerCount, (_) => <Card>[]);
    var deckIndex = 0;

    // Deal two packets of four cards to each player, clockwise from the
    // player after the dealer. The packet order is retained in each hand.
    for (var packet = 0; packet < 2; packet++) {
      for (var cardInPacket = 0; cardInPacket < 4; cardInPacket++) {
        for (var offset = 0; offset < playerCount; offset++) {
          final playerIndex = (firstPlayerIndex + offset) % playerCount;
          hands[playerIndex].add(deck[deckIndex]);
          deckIndex++;
        }
      }
    }

    return hands;
  }
}
