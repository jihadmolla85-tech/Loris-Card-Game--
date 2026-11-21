import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  group('LORIS card display', () {
    test('shows L on the special LORIS card', () {
      const card = Card.loris(replacesRank: 7);
      expect(card.displayName, 'L');
      expect(card.isLoris, isTrue);
      expect(card.suit, isNull);
      expect(card.rank, isNull);
    });

    test('keeps J for the ordinary Jack card', () {
      const card = Card.normal(suit: Suit.hearts, rank: 11);
      expect(card.displayName, 'J');
      expect(card.isLoris, isFalse);
    });
  });
}
