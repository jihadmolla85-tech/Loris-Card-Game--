/// A public, sequenced command/event envelope for authoritative online play.
///
/// Do not send private cards or trust client-calculated scores in public events.
/// The server must validate the actor, turn, legal move and resulting score.
class OnlineGameEvent {
  const OnlineGameEvent({
    required this.eventId,
    required this.roomId,
    required this.playerId,
    required this.sequence,
    required this.type,
    required this.payload,
    required this.createdAt,
  })  : assert(sequence > 0),
        assert(eventId != ''),
        assert(roomId != ''),
        assert(playerId != ''),
        assert(type != '');

  final String eventId;
  final String roomId;
  final String playerId;
  final int sequence;
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt;

  factory OnlineGameEvent.fromJson(Map<String, Object?> json) {
    return OnlineGameEvent(
      eventId: json['eventId'] as String,
      roomId: json['roomId'] as String,
      playerId: json['playerId'] as String,
      sequence: json['sequence'] as int,
      type: json['type'] as String,
      payload: Map<String, Object?>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }

  Map<String, Object?> toJson() => {
        'eventId': eventId,
        'roomId': roomId,
        'playerId': playerId,
        'sequence': sequence,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
