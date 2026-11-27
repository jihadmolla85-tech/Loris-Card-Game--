import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';
import 'package:loris_card_game/game/models/loris_deck.dart';

void main() {
  group('LORIS special card and deck composition', () {
    test('four-player deck replaces only the Spades 7 with one LORIS', () {
      final deck = LorisDeck.create(PlayerCount.four, random: Random(7));

      expect(deck, hasLength(32));
      final special = deck.where((card) => card.isLoris).toList();
      expect(special, hasLength(1));
      expect(special.single.replacesRank, 7);

      for (final suit in Suit.values) {
        for (var rank = 7; rank <= 14; rank++) {
          final matching = deck.where((card) =>
              !card.isLoris && card.suit == suit && card.rank == rank);
          expect(matching.length, suit == Suit.spades && rank == 7 ? 0 : 1,
              reason: 'Unexpected $rank of $suit in four-player deck');
        }
      }
    });

    test('six-player deck replaces only the Spades 3 with one LORIS', () {
      final deck = LorisDeck.create(PlayerCount.six, random: Random(19));

      expect(deck, hasLength(48));
      final special = deck.where((card) => card.isLoris).toList();
      expect(special, hasLength(1));
      expect(special.single.replacesRank, 3);

      for (final suit in Suit.values) {
        for (var rank = 3; rank <= 14; rank++) {
          final matching = deck.where((card) =>
              !card.isLoris && card.suit == suit && card.rank == rank);
          expect(matching.length, suit == Suit.spades && rank == 3 ? 0 : 1,
              reason: 'Unexpected $rank of $suit in six-player deck');
        }
      }
    });
  });
}
