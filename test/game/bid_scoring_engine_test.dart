import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/engine/bid_scoring_engine.dart';

void main() {
  group('LORIS Bid Scoring Engine', () {
    late BidScoringEngine engine;

    setUp(() {
      engine = BidScoringEngine();
    });

    test('Successful bid 4 gives +4 and -4', () {
      engine.calculateAndApply(
        biddingTeam: 0,
        bidAmount: 4,
        tricksWonByBiddingTeam: 4,
      );
      expect(engine.teamAScore, 4);
      expect(engine.teamBScore, -4);
    });

    test('Successful bid 7 gives +7 and -7', () {
      engine.calculateAndApply(
        biddingTeam: 1,
        bidAmount: 7,
        tricksWonByBiddingTeam: 7,
      );
      expect(engine.teamAScore, -7);
      expect(engine.teamBScore, 7);
    });

    test('Successful bid 8 gives +16 and -16', () {
      engine.calculateAndApply(
        biddingTeam: 0,
        bidAmount: 8,
        tricksWonByBiddingTeam: 8,
      );
      expect(engine.teamAScore, 16);
      expect(engine.teamBScore, -16);
    });

    test('Failed bid 5 gives -10 and +10', () {
      engine.calculateAndApply(
        biddingTeam: 0,
        bidAmount: 5,
        tricksWonByBiddingTeam: 4,
      );
      expect(engine.teamAScore, -10);
      expect(engine.teamBScore, 10);
    });

    test('Failed bid 8 gives -16 and +16', () {
      engine.calculateAndApply(
        biddingTeam: 1,
        bidAmount: 8,
        tricksWonByBiddingTeam: 7,
      );
      expect(engine.teamAScore, 16);
      expect(engine.teamBScore, -16);
    });

    test('Scores remain opposite across rounds', () {
      engine.calculateAndApply(
        biddingTeam: 0,
        bidAmount: 4,
        tricksWonByBiddingTeam: 4,
      );
      engine.calculateAndApply(
        biddingTeam: 1,
        bidAmount: 5,
        tricksWonByBiddingTeam: 4,
      );

      expect(engine.teamAScore, 14);
      expect(engine.teamBScore, -14);
      expect(engine.teamAScore + engine.teamBScore, 0);
    });

    test('Bids 4 to 7 succeed at target', () {
      for (var bid = 4; bid <= 7; bid++) {
        final freshEngine = BidScoringEngine();
        freshEngine.calculateAndApply(
          biddingTeam: 0,
          bidAmount: bid,
          tricksWonByBiddingTeam: bid,
        );
        expect(freshEngine.teamAScore, bid);
        expect(freshEngine.teamBScore, -bid);
      }
    });

    test('Rejects invalid bid', () {
      expect(
        () => engine.calculateAndApply(
          biddingTeam: 0,
          bidAmount: 3,
          tricksWonByBiddingTeam: 4,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid trick count', () {
      expect(
        () => engine.calculateAndApply(
          biddingTeam: 0,
          bidAmount: 4,
          tricksWonByBiddingTeam: 9,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects invalid team', () {
      expect(
        () => engine.calculateAndApply(
          biddingTeam: 2,
          bidAmount: 4,
          tricksWonByBiddingTeam: 4,
        ),
        throwsArgumentError,
      );
    });

    test('Reset scores returns both teams to zero', () {
      engine.calculateAndApply(
        biddingTeam: 0,
        bidAmount: 8,
        tricksWonByBiddingTeam: 8,
      );
      engine.resetScores();
      expect(engine.teamAScore, 0);
      expect(engine.teamBScore, 0);
    });
  });
}
