enum PremiumStatus { free, active, gracePeriod, expired, cancelled }

class PlayerLevelProgress {
  const PlayerLevelProgress({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  })  : assert(level >= 1),
        assert(totalXp >= 0),
        assert(xpIntoLevel >= 0),
        assert(xpForNextLevel > 0),
        assert(xpIntoLevel < xpForNextLevel);

  final int level;
  final int totalXp;
  final int xpIntoLevel;
  final int xpForNextLevel;

  double get progress => xpIntoLevel / xpForNextLevel;
}

class PlayerProfile {
  const PlayerProfile({
    required this.playerId,
    required this.displayName,
    required this.avatarId,
    required this.level,
    required this.premiumStatus,
    this.premiumExpiresAt,
  });

  final String playerId;
  final String displayName;
  final String avatarId;
  final PlayerLevelProgress level;
  final PremiumStatus premiumStatus;
  final DateTime? premiumExpiresAt;

  bool get hasPremiumBadge => premiumStatus == PremiumStatus.active ||
      premiumStatus == PremiumStatus.gracePeriod;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.displayName,
    required this.avatarId,
    required this.rank,
    required this.rating,
    required this.level,
    required this.isPremium,
  })  : assert(rank > 0),
        assert(rating >= 0);

  final String playerId;
  final String displayName;
  final String avatarId;
  final int rank;
  final int rating;
  final int level;
  final bool isPremium;
}

class SeasonSummary {
  const SeasonSummary({
    required this.seasonId,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  }) : assert(seasonId != '');

  final String seasonId;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  bool isRunningAt(DateTime time) =>
      isActive && !time.isBefore(startsAt) && time.isBefore(endsAt);
}
