import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/bidding_round_controller.dart';
import 'package:loris_card_game/game/models/loris_card.dart';

void main() {
  List<List<Card>> makeHands(int playerCount) => List.generate(
        playerCount,
        (_) => List.generate(
          8,
          (index) => Card.normal(
            suit: Suit.clubs,
            rank: index + 3,
          ),
        ),
      );

  group('BiddingRoundController turn-by-turn bidding', () {
    test('human bid does not instantly resolve every AI bid', () {
      final controller = BiddingRoundController(
        hands: makeHands(4),
        dealerIndex: 3,
      );

      expect(controller.isHumanTurn, isTrue);
      expect(controller.history, isEmpty);

      controller.submitHumanBid(4);

      expect(controller.history, hasLength(1));
      expect(controller.history.single.playerIndex, 0);
      expect(controller.isAiTurn, isTrue);
      expect(controller.engine.currentPlayerIndex, 1);
    });

    test('each AI action advances exactly one player in a six-player game', () {
      final controller = BiddingRoundController(
        hands: makeHands(6),
        dealerIndex: 0,
      );

      expect(controller.isAiTurn, isTrue);
      expect(controller.history, isEmpty);

      final first = controller.submitNextAiBid();
      expect(first.playerIndex, 1);
      expect(controller.history, hasLength(1));
      expect(controller.engine.currentPlayerIndex, 2);

      final second = controller.submitNextAiBid();
      expect(second.playerIndex, 2);
      expect(controller.history, hasLength(2));
      expect(controller.engine.currentPlayerIndex, 3);
    });
  });
}
