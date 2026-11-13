import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';
import 'package:loris_card_game/game/models/loris_deck.dart';
import 'package:loris_card_game/game/engine/initial_dealer_selector.dart';

List<Card> orderedDeck(PlayerCount count, int jackPosition) {
  final deck = LorisDeck.create(count, random: Random(10));
  final jacks = deck.where((c) => c.rank == 11).toList();
  final others = deck.where((c) => c.rank != 11).toList();

  return [
    ...others.take(jackPosition),
    jacks.first,
    ...others.skip(jackPosition),
    ...jacks.skip(1),
  ];
}

void main() {
  group('Initial Dealer Selection', () {
    test('4-player game selects the first player who gets Jack', () {
      final deck = orderedDeck(PlayerCount.four, 6);

      final result = InitialDealerSelector.select(
        deck: deck,
        playerCount: 4,
        firstPlayerIndex: 1,
        random: Random(20),
      );

      expect(result.dealerIndex, 3);
      expect(result.jackCard.rank, 11);
      expect(result.drawnCards.length, 7);
    });

    test('6-player game selects the correct dealer', () {
      final deck = orderedDeck(PlayerCount.six, 7);

      final result = InitialDealerSelector.select(
        deck: deck,
        playerCount: 6,
        firstPlayerIndex: 4,
        random: Random(21),
      );

      expect(result.dealerIndex, 5);
      expect(result.jackCard.rank, 11);
      expect(result.drawnCards.length, 8);
    });

    test('all cards return and are shuffled', () {
      final deck = orderedDeck(PlayerCount.four, 6);

      final result = InitialDealerSelector.select(
        deck: deck,
        playerCount: 4,
        firstPlayerIndex: 0,
        random: Random(22),
      );

      expect(result.shuffledDeck.length, 32);
      expect(result.shuffledDeck.toSet(), deck.toSet());
    });

    test('invalid deck size is rejected', () {
      expect(
        () => InitialDealerSelector.select(
          deck: [],
          playerCount: 4,
          firstPlayerIndex: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
