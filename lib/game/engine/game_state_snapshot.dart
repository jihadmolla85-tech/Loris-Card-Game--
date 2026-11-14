
import '../models/loris_card.dart';

/// Serializable state required to save and resume a LORIS match.
class GameStateSnapshot {
  const GameStateSnapshot({
    this.version = 1,
    required this.dealerIndex,
    required this.dealerAdvanced,
    required this.teamAScore,
    required this.teamBScore,
    this.playerCount,
    this.originalDeck = const [],
    this.hands = const [],
    this.trumpSuit,
    this.biddingTeam,
    this.bidAmount,
    this.trickPlays = const [],
    this.completedTricks = 0,
    this.biddingTeamTricks = 0,
    this.isRoundScored = false,
    this.sixteenCallStatus = 'notCalled',
    this.sixteenCompletedTricks = 0,
    this.sixteenBiddingTeamTricks = 0,
    this.sixteenLastTrickWinnerIndex,
    this.sixteenCallerIndex,
    this.sixteenBiddingTeamPoints = 0,
    this.sixteenOpposingTeamPoints = 0,
    this.redealShouldRedeal = false,
    this.redealReasons = const [],
    this.redealDealerIndex,
  });

  final int version;
  final int dealerIndex;
  final bool dealerAdvanced;
  final int teamAScore;
  final int teamBScore;

  final int? playerCount;
  final List<Card> originalDeck;
  final List<List<Card>> hands;

  final Suit? trumpSuit;
  final int? biddingTeam;
  final int? bidAmount;
  final List<SnapshotTrickPlay> trickPlays;
  final int completedTricks;
  final int biddingTeamTricks;
  final bool isRoundScored;

  final String sixteenCallStatus;
  final int sixteenCompletedTricks;
  final int sixteenBiddingTeamTricks;
  final int? sixteenLastTrickWinnerIndex;
  final int? sixteenCallerIndex;
  final int sixteenBiddingTeamPoints;
  final int sixteenOpposingTeamPoints;

  final bool redealShouldRedeal;
  final List<String> redealReasons;
  final int? redealDealerIndex;

  Map<String, dynamic> toJson() => {
        'version': version,
        'dealerIndex': dealerIndex,
        'dealerAdvanced': dealerAdvanced,
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'playerCount': playerCount,
        'originalDeck': originalDeck.map(_cardToJson).toList(),
        'hands': hands
            .map((hand) => hand.map(_cardToJson).toList())
            .toList(),
        'trumpSuit': trumpSuit?.name,
        'biddingTeam': biddingTeam,
        'bidAmount': bidAmount,
        'trickPlays': trickPlays.map((play) => play.toJson()).toList(),
        'completedTricks': completedTricks,
        'biddingTeamTricks': biddingTeamTricks,
        'isRoundScored': isRoundScored,
        'sixteenCallStatus': sixteenCallStatus,
        'sixteenCompletedTricks': sixteenCompletedTricks,
        'sixteenBiddingTeamTricks': sixteenBiddingTeamTricks,
        'sixteenLastTrickWinnerIndex': sixteenLastTrickWinnerIndex,
        'sixteenCallerIndex': sixteenCallerIndex,
        'sixteenBiddingTeamPoints': sixteenBiddingTeamPoints,
        'sixteenOpposingTeamPoints': sixteenOpposingTeamPoints,
        'redealShouldRedeal': redealShouldRedeal,
        'redealReasons': redealReasons,
        'redealDealerIndex': redealDealerIndex,
      };

  factory GameStateSnapshot.fromJson(Map<String, dynamic> json) {
    final rawHands = json['hands'] as List? ?? const [];
    final rawDeck = json['originalDeck'] as List? ?? const [];
    final rawPlays = json['trickPlays'] as List? ?? const [];

    return GameStateSnapshot(
      version: _intValue(json, 'version', 1),
      dealerIndex: _intValue(json, 'dealerIndex'),
      dealerAdvanced: _boolValue(json, 'dealerAdvanced'),
      teamAScore: _intValue(json, 'teamAScore'),
      teamBScore: _intValue(json, 'teamBScore'),
      playerCount: json['playerCount'] as int?,
      originalDeck: rawDeck
          .map((value) => _cardFromJson(
                Map<String, dynamic>.from(value as Map),
              ))
          .toList(),
      hands: rawHands
          .map((hand) => (hand as List)
              .map((value) => _cardFromJson(
                    Map<String, dynamic>.from(value as Map),
                  ))
              .toList())
          .toList(),
      trumpSuit: _suitFromName(json['trumpSuit'] as String?),
      biddingTeam: json['biddingTeam'] as int?,
      bidAmount: json['bidAmount'] as int?,
      trickPlays: rawPlays
          .map((value) => SnapshotTrickPlay.fromJson(
                Map<String, dynamic>.from(value as Map),
              ))
          .toList(),
      completedTricks: _intValue(json, 'completedTricks'),
      biddingTeamTricks: _intValue(json, 'biddingTeamTricks'),
      isRoundScored: _boolValue(json, 'isRoundScored'),
      sixteenCallStatus:
          json['sixteenCallStatus'] as String? ?? 'notCalled',
      sixteenCompletedTricks:
          _intValue(json, 'sixteenCompletedTricks'),
      sixteenBiddingTeamTricks:
          _intValue(json, 'sixteenBiddingTeamTricks'),
      sixteenLastTrickWinnerIndex:
          json['sixteenLastTrickWinnerIndex'] as int?,
      sixteenCallerIndex: json['sixteenCallerIndex'] as int?,
      sixteenBiddingTeamPoints:
          _intValue(json, 'sixteenBiddingTeamPoints'),
      sixteenOpposingTeamPoints:
          _intValue(json, 'sixteenOpposingTeamPoints'),
      redealShouldRedeal: _boolValue(json, 'redealShouldRedeal'),
      redealReasons: (json['redealReasons'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      redealDealerIndex: json['redealDealerIndex'] as int?,
    );
  }

  static Map<String, dynamic> _cardToJson(Card card) => {
        'isLoris': card.isLoris,
        'suit': card.suit?.name,
        'rank': card.rank,
        'replacesRank': card.replacesRank,
      };

  static Card _cardFromJson(Map<String, dynamic> json) {
    if (json['isLoris'] == true) {
      return Card.loris(replacesRank: json['replacesRank'] as int?);
    }

    final suit = _suitFromName(json['suit'] as String?);
    final rank = json['rank'] as int?;

    if (suit == null || rank == null) {
      throw const FormatException('Invalid card in saved game.');
    }

    return Card.normal(suit: suit, rank: rank);
  }

  static Suit? _suitFromName(String? name) {
    if (name == null) return null;

    for (final suit in Suit.values) {
      if (suit.name == name) return suit;
    }

    throw FormatException('Unknown suit: $name');
  }

  static int _intValue(
    Map<String, dynamic> json,
    String key, [
    int fallback = 0,
  ]) =>
      json[key] as int? ?? fallback;

  static bool _boolValue(
    Map<String, dynamic> json,
    String key, [
    bool fallback = false,
  ]) =>
      json[key] as bool? ?? fallback;
}

class SnapshotTrickPlay {
  const SnapshotTrickPlay({
    required this.playerIndex,
    required this.card,
  });

  final int playerIndex;
  final Card card;

  Map<String, dynamic> toJson() => {
        'playerIndex': playerIndex,
        'card': GameStateSnapshot._cardToJson(card),
      };

  factory SnapshotTrickPlay.fromJson(Map<String, dynamic> json) {
    final card = json['card'];

    if (card is! Map) {
      throw const FormatException('Invalid played card in saved game.');
    }

    return SnapshotTrickPlay(
      playerIndex: json['playerIndex'] as int,
      card: GameStateSnapshot._cardFromJson(
        Map<String, dynamic>.from(card),
      ),
    );
  }
}
