import 'package:audioplayers/audioplayers.dart';

/// Local, distinct sound cues for the LORIS card table.
class LorisAudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String effect) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$effect.wav'));
    } catch (_) {
      // A muted or unsupported device must never interrupt the match.
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
