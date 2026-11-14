import 'dart:math';

import '../models/loris_card.dart';

class DeckShuffleEngine {
  DeckShuffleEngine({Random? random})
      : _random = random ?? Random();

  final Random _random;

  List<Card> shuffle(List<Card> deck) {
    final shuffledDeck = List<Card>.from(deck);

    for (var i = shuffledDeck.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);

      final temp = shuffledDeck[i];
      shuffledDeck[i] = shuffledDeck[j];
      shuffledDeck[j] = temp;
    }

    return shuffledDeck;
  }
}
