import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/online/models/player_progression.dart';

void main() {
  group('PlayerLevelProgress', () {
    test('calculates progress within the current level', () {
      const progress = PlayerLevelProgress(
        level: 3,
        totalXp: 250,
        xpIntoLevel: 50,
        xpForNextLevel: 100,
      );
      expect(progress.progress, 0.5);
    });
  });

  group('PlayerProfile', () {
    PlayerProfile profile(PremiumStatus status) => PlayerProfile(
          playerId: 'player-1',
          displayName: 'LORIS Player',
          avatarId: 'owl-1',
          level: const PlayerLevelProgress(
            level: 1,
            totalXp: 0,
            xpIntoLevel: 0,
            xpForNextLevel: 100,
          ),
          premiumStatus: status,
        );

    test('shows premium badge only for active and grace period', () {
      expect(profile(PremiumStatus.active).hasPremiumBadge, isTrue);
      expect(profile(PremiumStatus.gracePeriod).hasPremiumBadge, isTrue);
      expect(profile(PremiumStatus.free).hasPremiumBadge, isFalse);
      expect(profile(PremiumStatus.expired).hasPremiumBadge, isFalse);
      expect(profile(PremiumStatus.cancelled).hasPremiumBadge, isFalse);
    });
  });

  group('SeasonSummary', () {
    final startsAt = DateTime.utc(2026, 1, 1);
    final endsAt = DateTime.utc(2026, 2, 1);

    test('is running inside its active date range', () {
      final season = SeasonSummary(
        seasonId: 'season-1',
        name: 'Season One',
        startsAt: startsAt,
        endsAt: endsAt,
        isActive: true,
      );
      expect(season.isRunningAt(DateTime.utc(2026, 1, 15)), isTrue);
      expect(season.isRunningAt(startsAt), isTrue);
      expect(season.isRunningAt(endsAt), isFalse);
    });

    test('inactive season is never running', () {
      final season = SeasonSummary(
        seasonId: 'season-2',
        name: 'Archived Season',
        startsAt: startsAt,
        endsAt: endsAt,
        isActive: false,
      );
      expect(season.isRunningAt(DateTime.utc(2026, 1, 15)), isFalse);
    });
  });
}
