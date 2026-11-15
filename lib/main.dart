
import 'package:flutter/material.dart';
import 'game/engine/game_save_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LorisApp());
}

class LorisApp extends StatelessWidget {
  const LorisApp({super.key});

  static const Color navy = Color(0xFF07152E);
  static const Color blue = Color(0xFF102B55);
  static const Color gold = Color(0xFFD6B15E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LORIS – The Ultimate Card Game',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
          primary: gold,
          surface: blue,
        ),
        fontFamily: 'Roboto',
      ),
      home: const LorisHomeScreen(),
    );
  }
}

class LorisHomeScreen extends StatefulWidget {
  const LorisHomeScreen({super.key});

  @override
  State<LorisHomeScreen> createState() => _LorisHomeScreenState();
}

class _LorisHomeScreenState extends State<LorisHomeScreen> {
  final GameSaveService _saveService = GameSaveService();

  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _checkingSave = false;

  Future<void> _newGame() async {
    final playerCount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF102B55),
        title: const Text(
          'SELECT PLAYERS',
          style: TextStyle(
            color: LorisApp.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Choose the number of players',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 4),
            child: const Text('4 PLAYERS'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 6),
            child: const Text('6 PLAYERS'),
          ),
        ],
      ),
    );

    if (!mounted || playerCount == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameSetupScreen(
          playerCount: playerCount,
        ),
      ),
    );
  }

  Future<void> _resumeGame() async {
    if (_checkingSave) return;

    setState(() => _checkingSave = true);

    try {
      final snapshot = await _saveService.load();

      if (!mounted) return;

      if (snapshot == null) {
        _showMessage('No saved game found.');
      } else {
        _showMessage(
          'Saved match found. Game resume screen is being connected.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Unable to load saved game.');
      }
    } finally {
      if (mounted) {
        setState(() => _checkingSave = false);
      }
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF102B55),
          title: const Text(
            'SETTINGS',
            style: TextStyle(
              color: LorisApp.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Background Music',
                  style: TextStyle(color: Colors.white),
                ),
                value: _musicEnabled,
                activeThumbColor: LorisApp.gold,
                onChanged: (value) {
                  setState(() => _musicEnabled = value);
                  setDialogState(() => _musicEnabled = value);
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Sound Effects',
                  style: TextStyle(color: Colors.white),
                ),
                value: _soundEnabled,
                activeThumbColor: LorisApp.gold,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  setDialogState(() => _soundEnabled = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF102B55),
              Color(0xFF07152E),
              Color(0xFF030A16),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 76,
                    color: LorisApp.gold,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'LORIS',
                    style: TextStyle(
                      color: LorisApp.gold,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'THE ULTIMATE CARD GAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 38),
                  Container(
                    width: 190,
                    height: 2,
                    color: LorisApp.gold.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 38),
                  _menuButton(
                    icon: Icons.play_arrow_rounded,
                    title: 'NEW GAME',
                    onPressed: _newGame,
                    primary: true,
                  ),
                  const SizedBox(height: 16),
                  _menuButton(
                    icon: Icons.restore_rounded,
                    title: 'RESUME GAME',
                    onPressed: _checkingSave ? null : _resumeGame,
                  ),
                  const SizedBox(height: 16),
                  _menuButton(
                    icon: Icons.settings_rounded,
                    title: 'SETTINGS',
                    onPressed: _showSettings,
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'STRATEGY • TEAMWORK • VICTORY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String title,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: primary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: LorisApp.gold,
                foregroundColor: LorisApp.navy,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(title),
              style: OutlinedButton.styleFrom(
                foregroundColor: LorisApp.gold,
                side: const BorderSide(color: LorisApp.gold),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
    );
  }
}

class GameSetupScreen extends StatelessWidget {
  const GameSetupScreen({
    super.key,
    required this.playerCount,
  });

  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW MATCH'),
        backgroundColor: LorisApp.blue,
        foregroundColor: LorisApp.gold,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.style_rounded,
                size: 70,
                color: LorisApp.gold,
              ),
              const SizedBox(height: 24),
              Text(
                '$playerCount PLAYERS',
                style: const TextStyle(
                  color: LorisApp.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                playerCount == 4
                    ? '1 Human + 3 AI Players'
                    : '1 Human + 5 AI Players',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Game table and match initialization will be connected next.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
