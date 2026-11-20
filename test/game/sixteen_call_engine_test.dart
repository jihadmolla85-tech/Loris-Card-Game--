import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/sixteen_call_engine.dart';

void main() {
  group('LORIS 16 Call Engine', () {
    late SixteenCallEngine engine;

    SixteenCallEngine createEngine({
      int bid = 4,
      int team = 0,
      int players = 4,
    }) {
      return SixteenCallEngine(
        playerCount: players,
        biddingTeam: team,
        bidAmount: bid,
      );
    }

    void winFirstFour(SixteenCallEngine game) {
      game.recordTrickWinner(0);
      game.recordTrickWinner(2);
      game.recordTrickWinner(0);
      game.recordTrickWinner(2);
    }

    test('Allows bids 4 to 7', () {
      for (var bid = 4; bid <= 7; bid++) {
        expect(
          () => createEngine(bid: bid),
          returnsNormally,
        );
      }
    });

    test('Rejects bid 8 for 16 Call', () {
      expect(
        () => createEngine(bid: 8),
        throwsArgumentError,
      );
    });

    test('Rejects invalid bid', () {
      expect(
        () => createEngine(bid: 3),
        throwsArgumentError,
      );
    });

    test('Allows 4 and 6 player games', () {
      expect(
        () => createEngine(players: 4),
        returnsNormally,
      );
      expect(
        () => createEngine(players: 6),
        returnsNormally,
      );
    });

    test('Requires bidding team to reach its bid', () {
      engine = createEngine(bid: 5);
      winFirstFour(engine);

      expect(engine.canCall, isFalse);
      expect(
        () => engine.call16(callerPlayerIndex: 2),
        throwsStateError,
      );
    });

    test('Can call immediately after winning the bid number of consecutive tricks', () {
      engine = createEngine();
      winFirstFour(engine);
      expect(engine.canCall, isTrue);
      engine.call16(callerPlayerIndex: 2);
      expect(engine.status, SixteenCallStatus.inProgress);
    });

    test('An opponent trick prevents 16 call eligibility', () {
      engine = createEngine(bid: 4);
      engine.recordTrickWinner(0);
      engine.recordTrickWinner(1);
      engine.recordTrickWinner(2);
      engine.recordTrickWinner(0);
      expect(engine.canCall, isFalse);
      expect(() => engine.call16(callerPlayerIndex: 0), throwsStateError);
    });

    test('Only previous trick winner can call', () {
      engine = createEngine();
      winFirstFour(engine);

      expect(engine.canCall, isTrue);
      expect(
        () => engine.call16(callerPlayerIndex: 0),
        throwsStateError,
      );
    });

    test('Only bidding team member can call', () {
      engine = createEngine(team: 1);

      engine.recordTrickWinner(1);
      engine.recordTrickWinner(3);
      engine.recordTrickWinner(1);
      engine.recordTrickWinner(3);
      engine.recordTrickWinner(0);

      expect(engine.canCall, isFalse);
      expect(
        () => engine.call16(callerPlayerIndex: 0),
        throwsStateError,
      );
    });

    test('Previous trick winner can pass the one-time 16 decision', () {
      engine = createEngine();
      winFirstFour(engine);

      engine.pass16(callerPlayerIndex: 2);

      expect(engine.status, SixteenCallStatus.passed);
      expect(engine.canCall, isFalse);
      expect(
        () => engine.call16(callerPlayerIndex: 2),
        throwsStateError,
      );
    });

    test('Previous trick winner can make 16 Call', () {
      engine = createEngine();
      winFirstFour(engine);

      engine.call16(callerPlayerIndex: 2);

      expect(
        engine.status,
        SixteenCallStatus.inProgress,
      );
    });

    test('Winning all remaining tricks succeeds', () {
      engine = createEngine();
      winFirstFour(engine);
      engine.call16(callerPlayerIndex: 2);

      engine.recordTrickWinner(2);
      engine.recordTrickWinner(0);
      engine.recordTrickWinner(2);
      engine.recordTrickWinner(0);

      expect(
        engine.status,
        SixteenCallStatus.succeeded,
      );
      expect(engine.biddingTeamPoints, 16);
      expect(engine.opposingTeamPoints, -16);
      expect(engine.isRoundEnded, isTrue);
    });

    test('Losing one trick ends round immediately', () {
      engine = createEngine();
      winFirstFour(engine);
      engine.call16(callerPlayerIndex: 2);

      engine.recordTrickWinner(1);

      expect(
        engine.status,
        SixteenCallStatus.failed,
      );
      expect(engine.biddingTeamPoints, -16);
      expect(engine.opposingTeamPoints, 16);
      expect(engine.isRoundEnded, isTrue);
    });

    test('Cannot play after failed 16 Call', () {
      engine = createEngine();
      winFirstFour(engine);
      engine.call16(callerPlayerIndex: 2);
      engine.recordTrickWinner(1);

      expect(
        () => engine.recordTrickWinner(0),
        throwsStateError,
      );
    });

    test('Cannot call after all 8 tricks', () {
      engine = createEngine();

      for (var i = 0; i < 8; i++) {
        engine.recordTrickWinner(0);
      }

      expect(
        () => engine.call16(callerPlayerIndex: 0),
        throwsStateError,
      );
    });

    test('Rejects invalid player index', () {
      engine = createEngine();

      expect(
        () => engine.recordTrickWinner(4),
        throwsArgumentError,
      );
    });

    test('Rejects a second 16 Call', () {
      engine = createEngine();
      winFirstFour(engine);
      engine.call16(callerPlayerIndex: 2);

      expect(
        () => engine.call16(callerPlayerIndex: 2),
        throwsStateError,
      );
    });
  });
}
