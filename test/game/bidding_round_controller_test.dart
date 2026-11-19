import 'package:test/test.dart';
import 'package:loris_card_game/game/engine/bidding_round_controller.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  List<List<Card>> createHands() => List.generate(
        4,
        (_) => List.generate(
          8,
          (index) => Card.normal(
            suit: Suit.clubs,
            rank: 7 + index,
          ),
        ),
      );

  group('BiddingRoundController animated AI turns', () {
    test('does not resolve AI bids synchronously during construction', () {
      final controller = BiddingRoundController(
        hands: createHands(),
        dealerIndex: 2,
      );

      expect(controller.history, isEmpty);
      expect(controller.isAiTurn, isTrue);
      expect(controller.currentPlayerIndex, 3);
    });

    test('submits exactly one AI bid per call and yields to the human', () {
      final controller = BiddingRoundController(
        hands: createHands(),
        dealerIndex: 2,
      );

      final firstAiBid = controller.submitAiBid();
      expect(firstAiBid.playerIndex, 1);
      expect(controller.history, hasLength(1));
      expect(controller.isHumanTurn, isTrue);
      expect(controller.currentPlayerIndex, 0);

      controller.submitHumanBid(null);
      expect(controller.history, hasLength(2));
      expect(controller.isAiTurn, isTrue);
      expect(controller.currentPlayerIndex, 1);

      final nextAiBid = controller.submitAiBid();
      expect(nextAiBid.playerIndex, 3);
      expect(controller.history, hasLength(3));
      expect(controller.currentPlayerIndex, 2);
    });
  });
}
