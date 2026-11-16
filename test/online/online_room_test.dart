import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/online/models/online_game_event.dart';
import 'package:loris_card_game/online/models/online_room.dart';

void main() {
  group('OnlineRoom', () {
    final createdAt = DateTime.utc(2026, 11, 16, 12);

    test('round-trips a four-player room without private hand data', () {
      final room = OnlineRoom(
        roomId: 'room-1',
        roomCode: 'AB12CD',
        hostPlayerId: 'player-1',
        mode: OnlineGameMode.fourPlayers,
        status: OnlineRoomStatus.waiting,
        createdAt: createdAt,
        seats: [
          const OnlinePlayerSeat(
            playerId: 'player-1',
            displayName: 'Host',
            avatarId: 'owl',
            seatIndex: 0,
            isHost: true,
          ),
        ],
      );

      final restored = OnlineRoom.fromJson(room.toJson());
      expect(restored.roomCode, 'AB12CD');
      expect(restored.capacity, 4);
      expect(restored.openSeats, 3);
      expect(restored.seats.single.playerId, 'player-1');
      expect(restored.toJson().containsKey('hands'), isFalse);
    });

    test('rejects duplicate seats and over-capacity rooms', () {
      const player = OnlinePlayerSeat(
        playerId: 'p1',
        displayName: 'Player',
        avatarId: 'default',
        seatIndex: 0,
      );

      expect(
        () => OnlineRoom(
          roomId: 'room-1',
          roomCode: 'ABC123',
          hostPlayerId: 'p1',
          mode: OnlineGameMode.fourPlayers,
          status: OnlineRoomStatus.waiting,
          createdAt: createdAt,
          seats: [player, player],
        ),
        throwsArgumentError,
      );

      expect(
        () => OnlineRoom(
          roomId: 'room-2',
          roomCode: 'ABC124',
          hostPlayerId: 'p1',
          mode: OnlineGameMode.fourPlayers,
          status: OnlineRoomStatus.waiting,
          createdAt: createdAt,
          seats: List.generate(
            5,
            (index) => OnlinePlayerSeat(
              playerId: 'p$index',
              displayName: 'P$index',
              avatarId: 'default',
              seatIndex: index,
              isHost: index == 0,
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('supports six-player capacity', () {
      final room = OnlineRoom(
        roomId: 'room-6',
        roomCode: 'SIX666',
        hostPlayerId: 'p1',
        mode: OnlineGameMode.sixPlayers,
        status: OnlineRoomStatus.waiting,
        createdAt: createdAt,
        seats: const [
          OnlinePlayerSeat(
            playerId: 'p1',
            displayName: 'Host',
            avatarId: 'owl',
            seatIndex: 0,
            isHost: true,
          ),
        ],
      );

      expect(room.capacity, 6);
      expect(room.openSeats, 5);
    });
  });

  test('OnlineGameEvent round-trips a sequenced public action', () {
    final event = OnlineGameEvent(
      eventId: 'event-1',
      roomId: 'room-1',
      playerId: 'player-1',
      sequence: 1,
      type: 'player_ready',
      payload: const {'ready': true},
      createdAt: DateTime.utc(2026, 11, 16),
    );

    final restored = OnlineGameEvent.fromJson(event.toJson());
    expect(restored.sequence, 1);
    expect(restored.type, 'player_ready');
    expect(restored.payload['ready'], isTrue);
  });
}
