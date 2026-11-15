
import 'dart:math';

import 'package:flutter/material.dart';

import 'game/models/loris_card.dart' as loris;
import 'game/models/loris_deck.dart' as loris;
import 'game/engine/game_match_controller.dart';
import 'game/engine/match_score_engine.dart';
import 'game/engine/bid_scoring_engine.dart';
import 'game/engine/deal_controller.dart';
import 'game/engine/deck_shuffle_engine.dart';
import 'game/engine/deck_validation_engine.dart';
import 'game/engine/redeal_controller.dart';
import 'game/engine/redeal_validation_engine.dart';
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
        backgroundColor: LorisApp.blue,
        title: const Text(
          'SELECT PLAYERS',
          style: TextStyle(color: LorisApp.gold),
        ),
        content: const Text('Choose the number of players'),
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
          'Saved match found. Resume screen is not connected yet.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to load saved game.');
      }
    } finally {
      if (mounted) {
        setState(() => _checkingSave = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: LorisApp.blue,
          title: const Text(
            'SETTINGS',
            style: TextStyle(color: LorisApp.gold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Background Music'),
                value: _musicEnabled,
                activeThumbColor: LorisApp.gold,
                onChanged: (value) {
                  setState(() => _musicEnabled = value);
                  setDialogState(() => _musicEnabled = value);
                },
              ),
              SwitchListTile(
                title: const Text('Sound Effects'),
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
              padding: const EdgeInsets.all(28),
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
                    color: LorisApp.gold,
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

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({
    super.key,
    required this.playerCount,
  });

  final int playerCount;

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  bool _starting = false;
  String? _error;

  int? _dealerIndex;
  List<List<loris.Card>>? _hands;

  GameMatchController? _matchController;
  DealController? _dealController;

  void _startGame() {
    if (_starting || _hands != null) return;

    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final random = Random();

      final playerCount = widget.playerCount;

      final playerType = playerCount == 4
          ? loris.PlayerCount.four
          : loris.PlayerCount.six;

      // Create the correct LORIS deck.
      final deck = loris.LorisDeck.create(
        playerType,
        random: random,
      );

      // Prepare the dealing engine.
      final dealController = DealController(
        shuffleEngine: DeckShuffleEngine(random: random),
        redealController: RedealController(
          validationEngine: RedealValidationEngine(),
        ),
        deckValidationEngine: DeckValidationEngine(),
      );

      final matchController = GameMatchController(
        initialDealerIndex: 0,
        matchScoreEngine: MatchScoreEngine(),
        bidScoringEngine: BidScoringEngine(),
        dealController: dealController,
      );

      // Random starting seat; first player to draw a Jack is dealer.
      final selection = matchController.selectInitialDealer(
        deck: deck,
        playerCount: playerCount,
        random: random,
      );

      // Deal eight cards to each player, starting right of dealer.
      final hands = dealController.deal(
        deck: selection.shuffledDeck,
        playerCount: playerCount,
        dealerIndex: selection.dealerIndex,
      );

      setState(() {
        _matchController = matchController;
        _dealController = dealController;
        _dealerIndex = selection.dealerIndex;
        _hands = hands;
        _starting = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _starting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hands = _hands;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW MATCH'),
        backgroundColor: LorisApp.blue,
        foregroundColor: LorisApp.gold,
      ),
      body: SafeArea(
        child: hands == null
            ? _buildStartPanel()
            : _buildDealtGame(hands),
      ),
    );
  }

  Widget _buildStartPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_rounded,
              size: 76,
              color: LorisApp.gold,
            ),
            const SizedBox(height: 24),
            Text(
              '${widget.playerCount} PLAYERS',
              style: const TextStyle(
                color: LorisApp.gold,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.playerCount == 4
                  ? '1 Human + 3 AI Players'
                  : '1 Human + 5 AI Players',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Teams: A - B - A - B',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (widget.playerCount == 6) ...[
              const SizedBox(height: 6),
              const Text(
                'A - B - A - B - A - B',
                style: TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _starting ? null : _startGame,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  _starting ? 'STARTING...' : 'START MATCH',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LorisApp.gold,
                  foregroundColor: LorisApp.navy,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDealtGame(List<List<loris.Card>> hands) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(
            Icons.verified,
            color: LorisApp.gold,
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            'CARDS DEALT SUCCESSFULLY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LorisApp.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dealer: Player ${_dealerIndex! + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'First deal starts from the dealer’s right.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          const Divider(color: LorisApp.gold),
          const Text(
            'PLAYER SEATING',
            style: TextStyle(
              color: LorisApp.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(hands.length, (index) {
            final isHuman = index == 0;
            final team = index.isEven ? 'TEAM A' : 'TEAM B';
            final isDealer = index == _dealerIndex;

            return Card(
              color: LorisApp.blue,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: LorisApp.gold,
                  foregroundColor: LorisApp.navy,
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  isHuman ? 'You' : 'AI Player ${index}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '$team • ${hands[index].length} cards',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: isDealer
                    ? const Text(
                        'DEALER',
                        style: TextStyle(
                          color: LorisApp.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            );
          }),
          const SizedBox(height: 22),
          const Text(
            'YOUR HAND',
            style: TextStyle(
              color: LorisApp.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: hands[0]
                .map((card) => _playingCard(card))
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Initial dealing is connected. Bidding and the playable game table are the next integration tasks.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _playingCard(loris.Card card) {
    final isLoris = card.isLoris;

    final suit = card.suit;
    final isRed = suit == loris.Suit.hearts ||
        suit == loris.Suit.diamonds;

    final suitSymbol = switch (suit) {
      loris.Suit.clubs => '♣',
      loris.Suit.diamonds => '♦',
      loris.Suit.hearts => '♥',
      loris.Suit.spades => '♠',
      null => '',
    };

    return Container(
      width: 62,
      height: 92,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isLoris ? LorisApp.gold : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LorisApp.gold,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 5,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isLoris
              ? 'LORIS'
              : '${card.displayName}\n$suitSymbol',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isLoris
                ? LorisApp.navy
                : (isRed ? Colors.red : Colors.black87),
            fontSize: isLoris ? 12 : 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
