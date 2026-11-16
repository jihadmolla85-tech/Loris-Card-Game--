import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../engine/loris_music_service.dart';

class LorisMusicPlayerDialog extends StatefulWidget {
  const LorisMusicPlayerDialog({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
  });
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;

  @override
  State<LorisMusicPlayerDialog> createState() => _LorisMusicPlayerDialogState();
}

class _LorisMusicPlayerDialogState extends State<LorisMusicPlayerDialog> {
  final LorisMusicService _music = LorisMusicService.instance;
  final TextEditingController _search = TextEditingController();
  String _language = 'সব';
  String? _message;

  @override
  void initState() {
    super.initState();
    _music.setEnabled(widget.enabled);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<int> get _visibleIndexes {
    final query = _search.text.trim().toLowerCase();
    return List<int>.generate(lorisPlaylist.length, (i) => i).where((i) {
      final track = lorisPlaylist[i];
      final languageMatches = _language == 'সব' || track.language == _language;
      final textMatches = query.isEmpty ||
          track.title.toLowerCase().contains(query) ||
          track.artist.toLowerCase().contains(query);
      return languageMatches && textMatches;
    }).toList();
  }

  Future<void> _play(int index) async {
    setState(() => _message = null);
    try {
      await _music.playTrack(index);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message =
          'এই গানের অডিও ফাইল যোগ করা হয়নি। অনুমোদিত MP3 assets/music ফোল্ডারে রাখতে হবে।');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = _music.currentIndex;
    return AlertDialog(
      backgroundColor: const Color(0xFF102B55),
      title: Row(children: [
        const Icon(Icons.library_music, color: Color(0xFFD6B15E)),
        const SizedBox(width: 10),
        const Expanded(child: Text('LORIS MUSIC')),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ]),
      content: SizedBox(
        width: 520,
        height: MediaQuery.of(context).size.height * 0.68,
        child: Column(children: [
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Background music'),
            value: widget.enabled,
            activeThumbColor: const Color(0xFFD6B15E),
            onChanged: (value) async {
              widget.onEnabledChanged(value);
              await _music.setEnabled(value);
              if (mounted) setState(() {});
            },
          ),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'গান বা শিল্পীর নাম খুঁজুন',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'সব', label: Text('সব')),
              ButtonSegment(value: 'বাংলা', label: Text('বাংলা')),
              ButtonSegment(value: 'হিন্দি', label: Text('হিন্দি')),
              ButtonSegment(value: 'English', label: Text('English')),
            ],
            selected: {_language},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _language = value.first),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _visibleIndexes.length,
              itemBuilder: (context, row) {
                final index = _visibleIndexes[row];
                final track = lorisPlaylist[index];
                final selected = current == index;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: CircleAvatar(
                    backgroundColor: selected ? const Color(0xFFD6B15E) : Colors.white12,
                    child: Icon(
                      selected && _music.playerState == PlayerState.playing
                          ? Icons.equalizer : Icons.music_note,
                      color: selected ? const Color(0xFF07152E) : Colors.white70,
                    ),
                  ),
                  title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${track.artist} • ${track.language}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Color(0xFFD6B15E)),
                    onPressed: () => _play(index),
                  ),
                  onTap: () => _play(index),
                );
              },
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_message!, style: const TextStyle(color: Colors.amber, fontSize: 11)),
            ),
          const Divider(color: Colors.white24),
          Row(children: [
            IconButton(tooltip: 'Previous', onPressed: _music.playPrevious,
                icon: const Icon(Icons.skip_previous)),
            IconButton.filled(
              tooltip: 'Play or pause',
              onPressed: () async {
                try {
                  await _music.togglePlayback();
                } catch (_) {
                  if (mounted) setState(() => _message =
                      'অডিও ফাইল পাওয়া যায়নি। আগে অনুমোদিত MP3 যোগ করুন।');
                }
                if (mounted) setState(() {});
              },
              icon: Icon(_music.playerState == PlayerState.playing
                  ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(tooltip: 'Next', onPressed: _music.playNext,
                icon: const Icon(Icons.skip_next)),
            const SizedBox(width: 8),
            const Icon(Icons.volume_down, size: 18),
            Expanded(child: Slider(
              value: _music.volume,
              onChanged: (value) {
                _music.setVolume(value);
                setState(() {});
              },
              activeColor: const Color(0xFFD6B15E),
            )),
            IconButton(
              tooltip: _music.shuffleEnabled ? 'Shuffle on' : 'Shuffle off',
              onPressed: () => setState(() =>
                  _music.shuffleEnabled = !_music.shuffleEnabled),
              icon: Icon(Icons.shuffle,
                  color: _music.shuffleEnabled ? const Color(0xFFD6B15E) : Colors.white54),
            ),
          ]),
          if (current != null)
            Text('এখন চলছে: ${lorisPlaylist[current].title}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }
}
