import 'dart:async';

import 'models/online_game_event.dart';
import 'models/online_room.dart';

/// Backend contract for online rooms.
///
/// Implementations must enforce room membership and game rules server-side,
/// keep each player's hand private, and reject stale event sequence numbers.
abstract interface class OnlineRoomService {
  Stream<OnlineRoom> watchRoom(String roomId);

  Stream<OnlineGameEvent> watchGameEvents(
    String roomId, {
    required int afterSequence,
  });

  Future<OnlineRoom> createRoom({
    required String playerId,
    required String displayName,
    required String avatarId,
    required OnlineGameMode mode,
  });

  Future<OnlineRoom> joinRoom({
    required String roomCode,
    required String playerId,
    required String displayName,
    required String avatarId,
  });

  Future<void> setReady({
    required String roomId,
    required String playerId,
    required bool isReady,
  });

  Future<void> submitAction({
    required String roomId,
    required String playerId,
    required String actionType,
    required Map<String, Object?> payload,
    required int expectedSequence,
  });

  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  });

  Future<void> dispose();
}

/// A typed exception that UI code can translate into a friendly message.
class OnlineRoomException implements Exception {
  const OnlineRoomException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'OnlineRoomException($code): $message';
}
