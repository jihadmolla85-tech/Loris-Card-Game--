
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/dealer_rotation_engine.dart';

void main() {
  group('LORIS Dealer Rotation Engine', () {
    test('Keeps same dealer during redeal', () {
      final result = DealerRotationEngine.nextDealerIndex(
        currentDealerIndex: 2,
        playerCount: 4,
        dealerTeamScore: 5,
        isRedeal: true,
      );

      expect(result, 2);
    });

    test('Keeps same dealer when team score is below +1', () {
      final result = DealerRotationEngine.nextDealerIndex(
        currentDealerIndex: 1,
        playerCount: 4,
        dealerTeamScore: 0,
        isRedeal: false,
      );

      expect(result, 1);
    });

    test('Moves dealer counterclockwise in four-player game', () {
      final result = DealerRotationEngine.nextDealerIndex(
        currentDealerIndex: 1,
        playerCount: 4,
        dealerTeamScore: 1,
        isRedeal: false,
      );

      expect(result, 2);
    });

    test('Moves dealer counterclockwise in six-player game', () {
      final result = DealerRotationEngine.nextDealerIndex(
        currentDealerIndex: 4,
        playerCount: 6,
        dealerTeamScore: 2,
        isRedeal: false,
      );

      expect(result, 3);
    });

    test('Wraps dealer index counterclockwise', () {
      final result = DealerRotationEngine.nextDealerIndex(
        currentDealerIndex: 3,
        playerCount: 4,
        dealerTeamScore: 1,
        isRedeal: false,
      );

      expect(result, 0);
    });

    test('Wraps dealer index counterclockwise in six-player game', () {
      final result = DealerRotationEngine.nextDealerIndex(
        currentDealerIndex: 5,
        playerCount: 6,
        dealerTeamScore: 1,
        isRedeal: false,
      );

      expect(result, 4);
    });

    test('Rejects invalid player count', () {
      expect(
        () => DealerRotationEngine.nextDealerIndex(
          currentDealerIndex: 0,
          playerCount: 5,
          dealerTeamScore: 1,
          isRedeal: false,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid dealer index', () {
      expect(
        () => DealerRotationEngine.nextDealerIndex(
          currentDealerIndex: 4,
          playerCount: 4,
          dealerTeamScore: 1,
          isRedeal: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
