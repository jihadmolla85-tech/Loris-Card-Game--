import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class LorisMusicTrack {
  const LorisMusicTrack(this.title, this.artist, this.language, this.fileName);
  final String title;
  final String artist;
  final String language;
  final String fileName;
  String get assetPath => 'music/$fileName';
}

// Track metadata only. Copyrighted recordings are not bundled in this repository.
const List<LorisMusicTrack> lorisPlaylist = [
  LorisMusicTrack('কফি হাউজের সেই আড্ডাটা','মান্না দে','বাংলা','coffee-house.mp3'),
  LorisMusicTrack('পৃথিবীটা নাকি ছোট হতে হতে','মহীনের ঘোড়াগুলি','বাংলা','prithibita-naki.mp3'),
  LorisMusicTrack('এই অবেলায়','শিরোনামহীন','বাংলা','ei-obelay.mp3'),
  LorisMusicTrack('হাসিমুখ','শিরোনামহীন','বাংলা','hashimukh.mp3'),
  LorisMusicTrack('একা পাখি','চিরকুট','বাংলা','eka-pakhi.mp3'),
  LorisMusicTrack('আমারও পরান যাহা চায়','রবীন্দ্রসংগীত','বাংলা','amar-o-poran.mp3'),
  LorisMusicTrack('তুমি আমার বসুন্ধরা','বাংলা','বাংলা','tumi-amar-boshundhora.mp3'),
  LorisMusicTrack('মন মাঝি খবরদার','ফোক','বাংলা','mon-majhi.mp3'),
  LorisMusicTrack('আবার হাসিমুখ','শিরোনামহীন','বাংলা','abar-hashimukh.mp3'),
  LorisMusicTrack('আভাস','তানযীর তুহিন','বাংলা','avash.mp3'),
  LorisMusicTrack('পথ চলা','আর্টসেল','বাংলা','poth-chola.mp3'),
  LorisMusicTrack('ধূসর সময়','আর্টসেল','বাংলা','dhushor-shomoy.mp3'),
  LorisMusicTrack('বাবা','জেমস','বাংলা','baba-james.mp3'),
  LorisMusicTrack('মা','জেমস','বাংলা','ma-james.mp3'),
  LorisMusicTrack('ফিরিয়ে দাও','মাইলস','বাংলা','firiye-dao.mp3'),
  LorisMusicTrack('নীলা','মাইলস','বাংলা','nila.mp3'),
  LorisMusicTrack('জাহাজী','শিরোনামহীন','বাংলা','jahaji.mp3'),
  LorisMusicTrack('পাষাণ','শিরোনামহীন','বাংলা','pashan.mp3'),
  LorisMusicTrack('বন্ধুরে','চিরকুট','বাংলা','bondhure.mp3'),
  LorisMusicTrack('কানামাছি','চিরকুট','বাংলা','kanamachi.mp3'),
  LorisMusicTrack('দিনের শেষে','অর্থহীন','বাংলা','diner-sheshe.mp3'),
  LorisMusicTrack('অদ্ভুত এক শহর','অর্থহীন','বাংলা','odvut-ek-shohor.mp3'),
  LorisMusicTrack('আলবিদা','জেমস / Life in a... Metro','হিন্দি','alvida.mp3'),
  LorisMusicTrack('নাদান পারিন্দে','এ আর রহমান, মোহিত চৌহান','হিন্দি','nadaan-parindey.mp3'),
  LorisMusicTrack('তাড়াপ তাড়াপ','কে কে','হিন্দি','tadap-tadap.mp3'),
  LorisMusicTrack('Tu Jaane Na','আতিফ আসলাম','হিন্দি','tu-jaane-na.mp3'),
  LorisMusicTrack('Tu Jo Mila','কে কে','হিন্দি','tu-jo-mila.mp3'),
  LorisMusicTrack('Kun Faya Kun','এ আর রহমান','হিন্দি','kun-faya-kun.mp3'),
  LorisMusicTrack('Ilahi','Yeh Jawaani Hai Deewani','হিন্দি','ilahi.mp3'),
  LorisMusicTrack('Set Fire to the Rain','Adele','English','set-fire-to-the-rain.mp3'),
  LorisMusicTrack('Faded','Alan Walker','English','faded.mp3'),
  LorisMusicTrack('On My Way','Alan Walker, Sabrina Carpenter, Farruko','English','on-my-way.mp3'),
  LorisMusicTrack('Dance Monkey','Tones and I','English','dance-monkey.mp3'),
  LorisMusicTrack('Love Me Like You Do','Ellie Goulding','English','love-me-like-you-do.mp3'),
  LorisMusicTrack('One Day','Arash feat. Helena','English','one-day.mp3'),
  LorisMusicTrack('Darkside','Alan Walker, Au/Ra, Tomine Harket','English','darkside.mp3'),
  LorisMusicTrack('Believer','Imagine Dragons','English','believer.mp3'),
  LorisMusicTrack('Thunder','Imagine Dragons','English','thunder.mp3'),
  LorisMusicTrack('Shape of You','Ed Sheeran','English','shape-of-you.mp3'),
  LorisMusicTrack('Cheap Thrills','Sia','English','cheap-thrills.mp3'),
  LorisMusicTrack('Counting Stars','OneRepublic','English','counting-stars.mp3'),
  LorisMusicTrack('Let Her Go','Passenger','English','let-her-go.mp3'),
  LorisMusicTrack('Unstoppable','Sia','English','unstoppable.mp3'),
  LorisMusicTrack('Alone','Alan Walker','English','alone.mp3'),
  LorisMusicTrack('Spectre','Alan Walker','English','spectre.mp3'),
];

class LorisMusicService {
  LorisMusicService._() {
    _player.setReleaseMode(ReleaseMode.stop);
    _player.onPlayerComplete.listen((_) {
      if (shuffleEnabled) {
        playRandom();
      } else {
        playNext();
      }
    });
  }

  static final LorisMusicService instance = LorisMusicService._();
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  int? currentIndex;
  bool enabled = true;
  bool shuffleEnabled = true;
  double volume = 0.35;
  bool _ducked = false;

  Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;
  PlayerState get playerState => _player.state;

  Future<void> playTrack(int index) async {
    if (!enabled || index < 0 || index >= lorisPlaylist.length) return;
    currentIndex = index;
    try {
      await _player.setVolume(_ducked ? volume * 0.22 : volume);
      await _player.play(AssetSource(lorisPlaylist[index].assetPath));
    } catch (_) {
      await _player.stop();
      rethrow;
    }
  }

  Future<void> togglePlayback() async {
    if (!enabled) return;
    if (_player.state == PlayerState.playing) {
      await _player.pause();
    } else if (currentIndex != null) {
      await _player.resume();
    } else {
      await playTrack(0);
    }
  }

  Future<void> playNext() async {
    final next = ((currentIndex ?? -1) + 1) % lorisPlaylist.length;
    await playTrack(next);
  }

  Future<void> playPrevious() async {
    final previous = ((currentIndex ?? 0) - 1 + lorisPlaylist.length) % lorisPlaylist.length;
    await playTrack(previous);
  }

  Future<void> playRandom() async {
    var next = _random.nextInt(lorisPlaylist.length);
    if (next == currentIndex) next = (next + 1) % lorisPlaylist.length;
    await playTrack(next);
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    if (!value) {
      await _player.pause();
    } else if (currentIndex != null && _player.state != PlayerState.playing) {
      await _player.resume();
    }
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0);
    await _player.setVolume(_ducked ? volume * 0.22 : volume);
  }

  Future<void> duck() async {
    _ducked = true;
    await _player.setVolume(volume * 0.22);
  }

  Future<void> unduck() async {
    _ducked = false;
    await _player.setVolume(volume);
  }
}
