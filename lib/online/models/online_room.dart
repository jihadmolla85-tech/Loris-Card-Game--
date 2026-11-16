import 'dart:convert';

/// Public room state only. Never put a player's private hand in this model.
enum OnlineRoomStatus { waiting, inProgress, finished, cancelled }

enum OnlineGameMode { fourPlayers, sixPlayers }

class OnlinePlayerSeat {
  const OnlinePlayerSeat({
    required this.playerId,
    required this.displayName,
    required this.avatarId,
    required this.seatIndex,
    this.isReady = false,
    this.isHost = false,
    this.isPremium = false,
    this.level = 1,
  }) : assert(seatIndex >= 0), assert(level >= 1);

  final String playerId;
  final String displayName;
  final String avatarId;
  final int seatIndex;
  final bool isReady;
  final bool isHost;
  final bool isPremium;
  final int level;

  factory OnlinePlayerSeat.fromJson(Map<String, Object?> json) {
    return OnlinePlayerSeat(
      playerId: json['playerId'] as String,
      displayName: json['displayName'] as String,
      avatarId: json['avatarId'] as String? ?? 'default',
      seatIndex: json['seatIndex'] as int,
      isReady: json['isReady'] as bool? ?? false,
      isHost: json['isHost'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      level: json['level'] as int? ?? 1,
    );
  }

  Map<String, Object?> toJson() => {
        'playerId': playerId,
        'displayName': displayName,
        'avatarId': avatarId,
        'seatIndex': seatIndex,
        'isReady': isReady,
        'isHost': isHost,
        'isPremium': isPremium,
        'level': level,
      };
}

class OnlineRoom {
  OnlineRoom({
    required this.roomId,
    required this.roomCode,
    required this.hostPlayerId,
    required this.mode,
    required this.status,
    required List<OnlinePlayerSeat> seats,
    required this.createdAt,
    this.revision = 0,
  }) : seats = List.unmodifiable(seats) {
    if (roomId.trim().isEmpty) throw ArgumentError('roomId cannot be empty');
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(roomCode)) {
      throw ArgumentError('roomCode must contain exactly 6 uppercase letters or digits');
    }
    if (revision < 0) throw ArgumentError.value(revision, 'revision');
    if (seats.length > capacity) throw ArgumentError('Room is over capacity');
    final ids = seats.map((seat) => seat.playerId).toSet();
    final indexes = seats.map((seat) => seat.seatIndex).toSet();
    if (ids.length != seats.length || indexes.length != seats.length) {
      throw ArgumentError('Player IDs and seat indexes must be unique');
    }
    if (seats.any((seat) => seat.seatIndex >= capacity)) {
      throw ArgumentError('Seat index exceeds room capacity');
    }
    if (seats.isNotEmpty && !ids.contains(hostPlayerId)) {
      throw ArgumentError('Host must occupy a seat in the room');
    }
  }

  final String roomId;
  final String roomCode;
  final String hostPlayerId;
  final OnlineGameMode mode;
  final OnlineRoomStatus status;
  final List<OnlinePlayerSeat> seats;
  final DateTime createdAt;
  final int revision;

  int get capacity => mode == OnlineGameMode.fourPlayers ? 4 : 6;
  int get openSeats => capacity - seats.length;
  bool get isFull => openSeats == 0;
  bool get everyoneReady => isFull && seats.every((seat) => seat.isReady);

  factory OnlineRoom.fromJson(Map<String, Object?> json) {
    return OnlineRoom(
      roomId: json['roomId'] as String,
      roomCode: json['roomCode'] as String,
      hostPlayerId: json['hostPlayerId'] as String,
      mode: OnlineGameMode.values.byName(json['mode'] as String),
      status: OnlineRoomStatus.values.byName(json['status'] as String),
      seats: (json['seats'] as List<Object?>? ?? const [])
          .map((seat) => OnlinePlayerSeat.fromJson(
                Map<String, Object?>.from(seat! as Map),
              ))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      revision: json['revision'] as int? ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'roomId': roomId,
        'roomCode': roomCode,
        'hostPlayerId': hostPlayerId,
        'mode': mode.name,
        'status': status.name,
        'seats': seats.map((seat) => seat.toJson()).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'revision': revision,
      };

  String encode() => jsonEncode(toJson());
}
