import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/bidding_engine.dart';

void main() {
  group('LORIS Bidding Engine', () {
    test('bidding starts from dealer right', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      expect(game.currentPlayerIndex, 1);
    });

    test('players act only once in order', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      game.submitBid(4);
      expect(game.currentPlayerIndex, 2);

      game.submitBid(null);
      expect(game.currentPlayerIndex, 3);

      game.submitBid(5);
      expect(game.currentPlayerIndex, 0);

      game.submitBid(null);

      expect(game.isComplete, true);
      expect(game.highestBid, 5);
      expect(game.highestBidder, 3);
    });

    test('pass cannot be taken back', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      game.submitBid(null);
      game.submitBid(4);
      game.submitBid(null);
      game.submitBid(5);

      expect(game.isComplete, true);
      expect(game.history.length, 4);
    });

    test('all pass means redeal', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      for (var i = 0; i < 4; i++) {
        game.submitBid(null);
      }

      expect(game.everyonePassed, true);
      expect(game.highestBidder, null);
    });

    test('bid must be between 4 and 8', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      expect(() => game.submitBid(3), throwsArgumentError);
      expect(() => game.submitBid(9), throwsArgumentError);
    });

    test('equal or lower bid is rejected', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      game.submitBid(5);

      expect(() => game.submitBid(5), throwsArgumentError);
      expect(() => game.submitBid(4), throwsArgumentError);
    });

    test('6-player bidding completes after six actions', () {
      final game = BiddingEngine(
        playerCount: 6,
        dealerIndex: 2,
      );

      expect(game.currentPlayerIndex, 3);

      game.submitBid(4);
      game.submitBid(null);
      game.submitBid(6);
      game.submitBid(null);
      game.submitBid(null);
      game.submitBid(null);

      expect(game.isComplete, true);
      expect(game.highestBid, 6);
      expect(game.highestBidder, 5);
    });

    test('cannot act after bidding completes', () {
      final game = BiddingEngine(
        playerCount: 4,
        dealerIndex: 0,
      );

      for (var i = 0; i < 4; i++) {
        game.submitBid(null);
      }

      expect(() => game.submitBid(4), throwsStateError);
    });
  });
}
