import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';
import 'package:loris_card_game/game/models/loris_deck.dart';
import 'package:loris_card_game/game/engine/card_dealer.dart';

void main() {
  group('LORIS Deck', () {
    test('4 players receive a 32-card deck', () {
      final deck = LorisDeck.create(
        PlayerCount.four,
        random: Random(1),
      );

      expect(deck.length, 32);
      expect(deck.where((c) => c.isLoris).length, 1);
      expect(
        deck.where((c) => c.replacesRank == 7).length,
        1,
      );
    });

    test('6 players receive a 48-card deck', () {
      final deck = LorisDeck.create(
        PlayerCount.six,
        random: Random(2),
      );

      expect(deck.length, 48);
      expect(deck.where((c) => c.isLoris).length, 1);
      expect(
        deck.where((c) => c.replacesRank == 3).length,
        1,
      );
    });

    test('all cards are unique', () {
      final deck = LorisDeck.create(
        PlayerCount.four,
        random: Random(3),
      );

      expect(deck.toSet().length, deck.length);
    });
  });

  group('Card Dealing', () {
    test('4 players get 8 cards each', () {
      final deck = LorisDeck.create(
        PlayerCount.four,
        random: Random(4),
      );

      final hands = CardDealer.deal(
        deck: deck,
        playerCount: 4,
        firstPlayerIndex: 1,
      );

      expect(hands.length, 4);
      expect(hands.every((hand) => hand.length == 8), true);
      expect(hands[1].first, deck.first);
    });

    test('6 players get 8 cards each', () {
      final deck = LorisDeck.create(
        PlayerCount.six,
        random: Random(5),
      );

      final hands = CardDealer.deal(
        deck: deck,
        playerCount: 6,
        firstPlayerIndex: 2,
      );

      expect(hands.length, 6);
      expect(hands.every((hand) => hand.length == 8), true);
      expect(hands[2].first, deck.first);
    });
  });
}
