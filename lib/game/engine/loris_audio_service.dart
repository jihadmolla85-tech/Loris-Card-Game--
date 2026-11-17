import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Local, distinct sound cues for the LORIS card table.
class LorisAudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String effect) async {
    try {
      await _player.stop();
      if (effect == 'card_place') {
        // A short, soft airy "swup" with a warm landing instead of a squeaky tap.
        await _player.setVolume(0.38);
        await _player.play(BytesSource(_softCardSwishWav()));
      } else {
        await _player.setVolume(0.72);
        await _player.play(AssetSource('sounds/$effect.wav'));
      }
    } catch (_) {
      // A muted or unsupported device must never interrupt the match.
    }
  }

  Uint8List _softCardSwishWav() {
    const sampleRate = 22050;
    const sampleCount = 5292; // 240 ms
    final bytes = ByteData(44 + sampleCount * 2);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + sampleCount * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, sampleCount * 2, Endian.little);

    var random = 0x4C4F5249;
    var lowPass = 0.0;
    var previous = 0.0;
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      random = (random * 1103515245 + 12345) & 0x7fffffff;
      final noise = (random / 0x3fffffff) - 1.0;
      lowPass = noise * 0.16 + lowPass * 0.84;
      final airy = (noise - lowPass) * (0.9 - 0.45 * (t / 0.24));
      final frequency = 155 - 55 * (t / 0.24);
      final phase = 2 * math.pi * (frequency * t - 22 * t * t);
      final landing = math.sin(phase) * math.exp(-math.pow((t - 0.17) / 0.065, 2)) * 0.14;
      final envelope = math.pow(math.sin(math.pi * t / 0.24), 1.25) * math.exp(-t * 1.8);
      final sample = ((airy * 0.19) + landing) * envelope * 0.62;
      previous = sample;
      final pcm = (previous * 32767).round().clamp(-32768, 32767).toInt();
      bytes.setInt16(44 + i * 2, pcm, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
