import 'dart:math';
import 'package:flutter/services.dart';
import 'game/engine/loris_audio_service.dart';
import 'game/widgets/dealer_reveal_dialog.dart';
import 'game/widgets/loris_portrait_avatar.dart';
import 'game/engine/game_settings_service.dart';
import 'package:material_ui/material_ui.dart';

import 'game/models/loris_card.dart' as loris;
import 'game/models/loris_deck.dart' as loris_deck;

import 'game/engine/game_match_controller.dart';
import 'game/engine/match_score_engine.dart';
import 'game/engine/bid_scoring_engine.dart';
import 'game/engine/deal_controller.dart';
import 'game/engine/deck_shuffle_engine.dart';
import 'game/engine/deck_validation_engine.dart';
import 'game/engine/redeal_controller.dart';
import 'game/engine/redeal_validation_engine.dart';
import 'game/engine/game_save_service.dart';
import 'game/engine/game_state_snapshot.dart';
import 'game/engine/bidding_round_controller.dart';
import 'game/engine/trump_selection_engine.dart';
import 'game/engine/trick_engine.dart';
import 'game/ai/ai_card_play_strategy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LorisApp());
}

// ============================================================
// APP
// ============================================================

class LorisApp extends StatelessWidget {
  const LorisApp({super.key});

  static const Color navy = Color(0xFF07152E);
  static const Color blue = Color(0xFF102B55);
  static const Color gold = Color(0xFFD6B15E);
  static const Color tableGreen = Color(0xFF075239);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LORIS – The Ultimate Card Game',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
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

// ============================================================
// HOME SCREEN
// ============================================================

class LorisHomeScreen extends StatefulWidget {
  const LorisHomeScreen({super.key});

  @override
  State<LorisHomeScreen> createState() => _LorisHomeScreenState();
}

class _LorisHomeScreenState extends State<LorisHomeScreen> {
  final GameSaveService _saveService = GameSaveService();
  final GameSettingsService _settingsService = GameSettingsService();

  bool _loading = false;
  bool _musicEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.load();
      if (!mounted) return;
      setState(() {
        _musicEnabled = settings.musicEnabled;
        _soundEnabled = settings.soundEnabled;
      });
    } catch (_) {
      // Keep safe defaults if local preferences cannot be read.
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsService.save(
        GameSettings(
          musicEnabled: _musicEnabled,
          soundEnabled: _soundEnabled,
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save settings on this device.');
      }
    }
  }

  Future<void> _newGame() async {
    final playerCount = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LorisApp.blue,
          title: const Text('SELECT PLAYERS'),
          content: const Text('Choose your game mode.'),
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
        );
      },
    );

    if (!mounted || playerCount == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(playerCount: playerCount),
      ),
    );
  }

  Future<void> _resumeGame() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final snapshot = await _saveService.load();

      if (!mounted) return;

      if (snapshot == null ||
          snapshot.playerCount == null ||
          snapshot.hands.isEmpty) {
        _showMessage('No saved match found.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            playerCount: snapshot.playerCount!,
            savedSnapshot: snapshot,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Could not resume match: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openRules() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LorisApp.blue,
        title: const Text('HOW TO PLAY LORIS'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                _RuleSection(
                  title: 'GAME SETUP',
                  body: 'Choose 4 or 6 players. Every player receives 8 cards. '
                      'Teams alternate around the table: A-B-A-B (or A-B-A-B-A-B). '
                      'The first team to reach 32 points wins.',
                ),
                _RuleSection(
                  title: 'DECK',
                  body: 'Four-player games use ranks 7 through Ace. Six-player '
                      'games use ranks 3 through Ace. The designated Spades card '
                      'is replaced by the special LORIS card.',
                ),
                _RuleSection(
                  title: 'BIDDING & TRUMP',
                  body: 'Bidding starts with the player to the dealer’s right. '
                      'Players may pass. A bid must be higher than the current '
                      'highest bid. The winning bidder selects a trump suit they '
                      'also hold. A teammate may reveal one eligible card for '
                      'that selection; their other cards remain private.',
                ),
                _RuleSection(
                  title: 'PLAYING TRICKS',
                  body: 'Follow the suit led whenever possible. If you cannot '
                      'follow suit, you must play trump when you have one. If a '
                      'higher trump is available, you must overtrump. LORIS may '
                      'be played at any time and is the highest card.',
                ),
                _RuleSection(
                  title: 'SCORING',
                  body: 'A successful normal bid scores the bid amount; a failed '
                      'bid gives the opposing team twice the bid. A successful '
                      '8 bid requires all 8 tricks and scores +16, while the '
                      'opponents score -16. A failed 8 bid scores -16 and the '
                      'opponents score +16.',
                ),
                _RuleSection(
                  title: 'CALL 16',
                  body: 'After winning the number of tricks equal to your bid, '
                      'a player may call 16 after winning the next trick. Their '
                      'team must then win every remaining trick. Losing even '
                      'one remaining trick gives that team -16.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              backgroundColor: LorisApp.blue,
              title: const Text('SETTINGS'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Background Music'),
                    value: _musicEnabled,
                    activeThumbColor: LorisApp.gold,
                    onChanged: (value) {
                      setState(() => _musicEnabled = value);
                      updateDialog(() => _musicEnabled = value);
                      _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Sound Effects'),
                    value: _soundEnabled,
                    activeThumbColor: LorisApp.gold,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                      updateDialog(() => _soundEnabled = value);
                      _saveSettings();
                    },
                  ),
                  const Text(
                    'Sound effects follow this setting during a match. Background music is not connected yet.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('CLOSE'),
                ),
              ],
            );
          },
        );
      },
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
              LorisApp.blue,
              LorisApp.navy,
              Color(0xFF030A16),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 82,
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
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 3,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    width: 190,
                    height: 2,
                    color: LorisApp.gold,
                  ),
                  const SizedBox(height: 38),
                  _menuButton(
                    'NEW GAME',
                    Icons.play_arrow,
                    _newGame,
                    primary: true,
                  ),
                  const SizedBox(height: 16),
                  _menuButton(
                    _loading ? 'LOADING...' : 'RESUME GAME',
                    Icons.restore,
                    _loading ? null : _resumeGame,
                  ),
                  const SizedBox(height: 16),
                  _menuButton(
                    'SETTINGS',
                    Icons.settings,
                    _openSettings,
                  ),
                  const SizedBox(height: 16),
                  _menuButton(
                    'HOW TO PLAY',
                    Icons.menu_book,
                    _openRules,
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'STRATEGY • TEAMWORK • VICTORY',
                    style: TextStyle(
                      color: Colors.white38,
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

  Widget _menuButton(
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool primary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: primary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: LorisApp.gold,
                foregroundColor: LorisApp.navy,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: LorisApp.gold,
                side: const BorderSide(color: LorisApp.gold),
              ),
            ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LorisApp.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

// ============================================================
// GAME SCREEN
// ============================================================

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.playerCount,
    this.savedSnapshot,
  });

  final int playerCount;
  final GameStateSnapshot? savedSnapshot;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final GameSaveService _saveService = GameSaveService();
  final GameSettingsService _settingsService = GameSettingsService();
  final LorisAudioService _audio = LorisAudioService();
  final Random _random = Random();
  bool _soundEnabled = true;

  static const List<String> _namePool = [
    // Names requested by the player.
    'Jihad', 'Tamim', 'Himel', 'Rana', 'Nahid', 'Shakib', 'Robin',
    'Jannat', 'Ayesha', 'Sheto', 'Shima', 'Roma',
    // Additional names to keep match line-ups varied.
    'Adnan', 'Fahim', 'Rafi', 'Nabil', 'Imran', 'Farhan',
    'Hasan', 'Arif', 'Sami', 'Rayhan', 'Mahin', 'Tanvir',
    'Mitu', 'Tania', 'Nusrat', 'Mim', 'Sumi', 'Rima',
    'Nila', 'Faria', 'Sumaiya', 'Tisha', 'Anika', 'Maliha',
  ];
  // Human character portraits only; no animal or object avatars.
  static const List<String> _avatarPool = [
    '👨🏻', '👩🏻', '👨🏼', '👩🏼', '👨🏽', '👩🏽',
    '👨🏾', '👩🏾', '👨🏿', '👩🏿', '🧑🏻‍🦱', '🧑🏼‍🦰',
    '👨🏻‍🦱', '👩🏻‍🦰', '👨🏽‍🦲', '👩🏽‍🦱',
    '👨🏾‍🦰', '👩🏾‍🦳', '🧑🏽‍🦱', '🧑🏾‍🦰',
  ];
  late final List<String> _playerNames;
  late final List<String> _playerAvatars;

  late final DealController _dealController;
  late final GameMatchController _matchController;

  List<List<loris.Card>>? _hands;

  BiddingRoundController? _biddingController;

  loris.Suit? _trumpSuit;

  bool _started = false;
  bool _finished = false;
  bool _passed16 = false;
  bool _busy = false;
  bool _isShuffling = false;
  bool _isDealing = false;
  int? _dealTargetPlayer;
  int _dealBatch = 0;
  int _dealCardNumber = 0;
  late final AnimationController _shuffleController;

  String _status = 'Press START MATCH to begin.';
  String? _error;

  int? _dealerIndex;

  int _trickNumber = 0;
  List<TrickPlay> _revealedTrickPlays = [];
  int? _collectingTrickWinner;
  loris.Card? _flyingCard;
  int? _flyingFromPlayer;
  bool _flightStarted = false;
  String? _playEffect;
  String? _winCelebration;
  
  @override
  void initState() {
    super.initState();
    _loadAudioSettings();
    _shuffleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

    final shuffledNames = List<String>.from(_namePool)..shuffle(_random);
    final shuffledAvatars = List<String>.from(_avatarPool)..shuffle(_random);
    _playerNames = [
      'YOU',
      ...shuffledNames.take(widget.playerCount - 1),
    ];
    _playerAvatars = [
      '🎮',
      ...shuffledAvatars.take(widget.playerCount - 1),
    ];

    _dealController = DealController(
      shuffleEngine: DeckShuffleEngine(random: _random),
      redealController: RedealController(
        validationEngine: RedealValidationEngine(),
      ),
      deckValidationEngine: DeckValidationEngine(),
    );

    _matchController = GameMatchController(
      initialDealerIndex: widget.savedSnapshot?.dealerIndex ?? 0,
      matchScoreEngine: MatchScoreEngine(),
      bidScoringEngine: BidScoringEngine(),
      dealController: _dealController,
    );

    final snapshot = widget.savedSnapshot;

    if (snapshot != null) {
      _restoreSavedGame(snapshot);
    }
  }

  Future<void> _loadAudioSettings() async {
    try {
      final settings = await _settingsService.load();
      if (!mounted) return;
      setState(() => _soundEnabled = settings.soundEnabled);
    } catch (_) {
      // Keep sound effects enabled if preferences are unavailable.
    }
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _animateCardToTable(int playerIndex, loris.Card card) async {
    if (!mounted) return;
    setState(() {
      _flyingCard = card;
      _flyingFromPlayer = playerIndex;
      _flightStarted = false;
      _playEffect = card.isLoris
          ? 'LORIS!'
          : card.suit == _trumpSuit
              ? 'TRUMP!'
              : null;
    });
    await Future.delayed(const Duration(milliseconds: 35));
    if (!mounted) return;
    setState(() => _flightStarted = true);
    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    setState(() {
      _flyingCard = null;
      _flyingFromPlayer = null;
      _flightStarted = false;
      _playEffect = null;
    });
  }

  Future<void> _playCardFeedback(loris.Card card) async {
    if (!_soundEnabled) return;
    if (card.isLoris) {
      await _audio.play('loris');
      await HapticFeedback.heavyImpact();
    } else if (card.suit == _trumpSuit) {
      await _audio.play('trump');
      await HapticFeedback.mediumImpact();
    } else {
      await _audio.play('card_place');
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _playShuffleSound() async {
    if (!_soundEnabled) return;
    await _audio.play('shuffle');
    await HapticFeedback.lightImpact();
  }

  // ----------------------------------------------------------
  // RESTORE
  // ----------------------------------------------------------

  void _restoreSavedGame(GameStateSnapshot snapshot) {
    try {
      _matchController.restoreSnapshot(snapshot);

      if (!_matchController.hasStarted) {
        _error = 'The saved match does not contain an active round.';
        _status = 'Unable to restore active match.';
        return;
      }

      _hands = _matchController.currentRound.trickEngine.hands;

      _dealerIndex = snapshot.dealerIndex;
      _trumpSuit = snapshot.trumpSuit;

      _started = true;
      _finished = _matchController.currentRound.isRoundEnded;

      _trickNumber = snapshot.completedTricks;

      _status = 'Saved match restored successfully.';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_finished) {
          _runAiTurns();
        }
      });
    } catch (e) {
      _error = 'Resume failed: $e';
      _status = 'Could not restore saved match.';
    }
  }

  // ----------------------------------------------------------
  // INITIAL DEAL
  // ----------------------------------------------------------

  Future<void> _startMatch() async {
    if (_busy || _hands != null) return;

    setState(() {
      _busy = true;
      _isShuffling = true;
      _error = null;
    });
    _shuffleController.repeat(reverse: true);

    try {
      await _playShuffleSound();
      await Future.delayed(const Duration(milliseconds: 1050));
      if (!mounted) return;
      final deck = loris_deck.LorisDeck.create(
        widget.playerCount == 4
            ? loris.PlayerCount.four
            : loris.PlayerCount.six,
        random: _random,
      );

      final dealerSelection = _matchController.selectInitialDealer(
        deck: deck,
        playerCount: widget.playerCount,
        random: _random,
      );
await DealerRevealDialog.show(
  context,
  drawnCards: dealerSelection.drawnCards,
  playerCount: widget.playerCount,
  dealerIndex: dealerSelection.dealerIndex,
  dealerName: _playerNames[dealerSelection.dealerIndex],
  dealerAvatar: _playerAvatars[dealerSelection.dealerIndex],
);
      _shuffleController.stop();
      if (mounted) setState(() => _isShuffling = false);

      final dealtHands = _dealController.deal(
        deck: dealerSelection.shuffledDeck,
        playerCount: widget.playerCount,
        dealerIndex: dealerSelection.dealerIndex,
      );

      setState(() {
        _dealerIndex = dealerSelection.dealerIndex;
        _hands = dealtHands;
        _isDealing = true;
        _dealTargetPlayer = null;
        _status = 'Dealing cards in two batches of four.';
      });

      await _animateDeal(dealerSelection.dealerIndex);
      if (!mounted) return;
      setState(() {
        _isDealing = false;
        _dealTargetPlayer = null;
        _status = 'Cards dealt. Bidding begins.';
      });
      _startBidding();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        _shuffleController.stop();
        setState(() {
          _busy = false;
          _isShuffling = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // BIDDING
  // ----------------------------------------------------------

  void _startBidding() {
    final hands = _hands;
    final dealer = _dealerIndex;

    if (hands == null || dealer == null) return;

    try {
      final controller = BiddingRoundController(
        hands: hands,
        dealerIndex: dealer,
        humanPlayerIndex: 0,
      );

      setState(() {
        _biddingController = controller;
        _started = false;
        _trumpSuit = null;

        _status = controller.isHumanTurn
            ? 'Your turn to bid.'
            : 'AI players are bidding.';
      });

      if (controller.isComplete) {
        _finishBidding();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _humanBid() async {
    final bidding = _biddingController;

    if (bidding == null ||
        !bidding.isHumanTurn ||
        bidding.isComplete ||
        _busy) {
      return;
    }

    final highestBid = bidding.highestBid ?? 3;

    final selectedBid = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB94F43), Color(0xFF762B2B), Color(0xFF4B1B24)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFD66F), width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -17),
                  child: Container(
                    width: 190,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD978), Color(0xFFB86A24)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFFFF0AE), width: 2),
                    ),
                    child: const Text('CALL', textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF762B2B), fontSize: 24,
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
                Text('CURRENT HIGHEST BID: ${bidding.highestBid ?? "-"}',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(5, (index) {
                    final value = index + 4;
                    final enabled = value > highestBid;
                    return SizedBox(
                      width: 68,
                      height: 66,
                      child: ElevatedButton(
                        onPressed: enabled ? () => Navigator.pop(dialogContext, value) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17833D),
                          disabledBackgroundColor: const Color(0xFF424242),
                          foregroundColor: const Color(0xFFFFE28A),
                          disabledForegroundColor: Colors.white24,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFFFD66F), width: 2),
                          ),
                          elevation: 7,
                        ),
                        child: Text('$value', style: const TextStyle(
                          fontSize: 27, fontWeight: FontWeight.w900)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 180,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, -1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF087C98),
                      foregroundColor: const Color(0xFFFFE28A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFFFD66F), width: 2),
                      ),
                    ),
                    child: const Text('PASS', style: TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedBid == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      bidding.submitHumanBid(
        selectedBid == -1 ? null : selectedBid,
      );

      setState(() {
        _status = bidding.isComplete
            ? 'Bidding complete.'
            : bidding.isHumanTurn
                ? 'Your turn to bid.'
                : 'AI players are bidding.';
      });

      if (bidding.isComplete) {
        await _finishBidding();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finishBidding() async {
    final bidding = _biddingController;

    if (bidding == null || !bidding.isComplete) return;

    if (bidding.everyonePassed) {
      await _validateAndContinue(
        everyonePassed: true,
        bidderHasTrump: true,
      );
      return;
    }

    final bidder = bidding.highestBidder;
    final amount = bidding.highestBid;

    if (bidder == null || amount == null) {
      setState(() => _error = 'Invalid bidding result.');
      return;
    }

    if (bidder == 0) {
      await _chooseHumanTrump(bidder);
    } else {
      await _chooseAiTrump(bidder);
    }
  }

  // ----------------------------------------------------------
  // TRUMP SELECTION
  // ----------------------------------------------------------

  Future<void> _chooseHumanTrump(int bidder) async {
    final hands = _hands;

    if (hands == null) return;

    final ownCards = hands[bidder]
        .where((card) => !card.isLoris && card.suit != null)
        .toList();

    // Teammate hands stay hidden. The bidder may reveal one hidden card,
    // but only cards whose suit the bidder also holds are eligible.
    final teammateCards = <int, List<loris.Card>>{};
    for (var player = 0; player < hands.length; player++) {
      if (player == bidder || player % 2 != bidder % 2) continue;
      final eligible = hands[player].where((card) {
        return !card.isLoris &&
            card.suit != null &&
            ownCards.any((ownCard) => ownCard.suit == card.suit);
      }).toList();
      if (eligible.isNotEmpty) teammateCards[player] = eligible;
    }

    final selected = await showDialog<MapEntry<int, loris.Card>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: LorisApp.blue,
          title: const Text('SELECT TRUMP'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: ListView(
              children: [
                const Text(
                  'YOUR CARDS',
                  style: TextStyle(
                    color: LorisApp.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...ownCards.map((card) => ListTile(
                      title: Text(_cardName(card)),
                      subtitle: const Text('Select this card as trump'),
                      onTap: () => Navigator.pop(
                        dialogContext,
                        MapEntry(bidder, card),
                      ),
                    )),
                if (teammateCards.isNotEmpty) ...[
                  const Divider(color: Colors.white24),
                  const Text(
                    'REVEAL ONE HIDDEN TEAMMATE CARD',
                    style: TextStyle(
                      color: LorisApp.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...teammateCards.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text('TEAMMATE ${entry.key + 1}'),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(entry.value.length, (index) {
                              final card = entry.value[index];
                              return InkWell(
                                onTap: () => Navigator.pop(
                                  dialogContext,
                                  MapEntry(entry.key, card),
                                ),
                                borderRadius: BorderRadius.circular(7),
                                child: Container(
                                  width: 46,
                                  height: 64,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF17345C),
                                    border: Border.all(color: LorisApp.gold),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(
                                    Icons.style,
                                    color: LorisApp.gold,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    await _applyTrump(
      bidder,
      selected.key,
      selected.value,
    );
  }

  Future<void> _chooseAiTrump(int bidder) async {
    final hands = _hands;

    if (hands == null) return;

    loris.Suit? bestSuit;
    var bestCount = -1;
    var cardOwner = bidder;

    // The bidder may only declare a suit that is also present in their
    // own hand, even when the revealed card belongs to a teammate.
    final bidderSuits = hands[bidder]
        .where((card) => !card.isLoris && card.suit != null)
        .map((card) => card.suit!)
        .toSet();

    for (var player = 0; player < hands.length; player++) {
      if (player % 2 != bidder % 2) continue;

      final counts = <loris.Suit, int>{
        for (final suit in bidderSuits) suit: 0,
      };

      for (final card in hands[player]) {
        if (!card.isLoris && card.suit != null &&
            bidderSuits.contains(card.suit)) {
          counts[card.suit!] = counts[card.suit!]! + 1;
        }
      }

      for (final entry in counts.entries) {
        if (entry.value > bestCount) {
          bestCount = entry.value;
          bestSuit = entry.key;
          cardOwner = player;
        }
      }
    }

    if (bestSuit == null || bestCount <= 0) {
      setState(() => _error = 'AI could not select trump.');
      return;
    }

    final selectedCard = hands[cardOwner].firstWhere(
      (card) => !card.isLoris && card.suit == bestSuit,
    );

    await _applyTrump(
      bidder,
      cardOwner,
      selectedCard,
    );
  }

  Future<void> _applyTrump(
    int bidder,
    int cardOwner,
    loris.Card selectedCard,
  ) async {
    final hands = _hands;
    final bidding = _biddingController;

    if (hands == null || bidding == null) return;

    try {
      final result = TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: bidder,
        highestBidderIndex: bidding.highestBidder!,
        cardOwnerIndex: cardOwner,
        selectedCard: selectedCard,
      );

      _trumpSuit = result.trumpSuit;

      await _validateAndContinue(
        everyonePassed: false,
        bidderHasTrump: result.bidderHasTrumpSuit,
        trump: result.trumpSuit,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  // ----------------------------------------------------------
  // REDEAL VALIDATION
  // ----------------------------------------------------------

  Future<void> _validateAndContinue({
    required bool everyonePassed,
    required bool bidderHasTrump,
    loris.Suit? trump,
  }) async {
    final bidding = _biddingController;

    if (bidding == null) return;

    try {
      // Store the validation result before the match controller
      // performs a redeal and resets the previous result.
      final validation = _dealController.validateDeal(
        everyonePassed: everyonePassed,
        bidderHasTrumpSuit: bidderHasTrump,
      );

      final redealRequired = validation.shouldRedeal;

      final newHands = _matchController.validateAndRedeal(
        everyonePassed: everyonePassed,
        bidderHasTrumpSuit: bidderHasTrump,
      );

      if (redealRequired) {
        setState(() {
          _hands = newHands;
          _trumpSuit = null;
          _started = false;
          _isDealing = true;
          _status = 'Redeal required. Same dealer remains.';
        });

        await _animateDeal(_dealerIndex!);
        if (!mounted) return;
        setState(() => _isDealing = false);
        _startBidding();
        return;
      }

      final selectedTrump = trump;
      final selectedBid = bidding.highestBid;
      final selectedBidder = bidding.highestBidder;

      if (selectedTrump == null ||
          selectedBid == null ||
          selectedBidder == null) {
        setState(() {
          _error = 'Trump or bidding information is missing.';
        });
        return;
      }

      _matchController.startRoundWithCurrentDeal(
        trumpSuit: selectedTrump,
        biddingTeam: selectedBidder % 2,
        bidAmount: selectedBid,
      );

      setState(() {
        _started = true;
        _finished = false;
        _trickNumber = 0;

        _status =
            'Round started. ${_suitName(selectedTrump)} is trump.';
      });

      await _runAiTurns();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  // ----------------------------------------------------------
  // CARD PLAY
  // ----------------------------------------------------------

  final AiCardPlayStrategy _aiCardPlayStrategy = const AiCardPlayStrategy();

  loris.Card _chooseAiCard(int playerIndex) {
    final engine = _matchController.currentRound.trickEngine;
    return _aiCardPlayStrategy.chooseCard(
      engine: engine,
      playerIndex: playerIndex,
    );
  }

  Future<void> _playHumanCard(loris.Card card) async {
    if (!_started || _finished || _busy) return;

    final round = _matchController.currentRound;

    if (round.nextPlayerIndex != 0) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _animateCardToTable(0, card);
      await _playCardFeedback(card);
      _matchController.playCard(0, card);

      await _afterCardPlayed();

      await _runAiTurns();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _runAiTurns() async {
    if (!_started || _finished || !mounted) return;

    var safetyCounter = 0;

    while (mounted &&
        !_matchController.currentRound.isRoundEnded &&
        _matchController.currentRound.nextPlayerIndex != 0 &&
        safetyCounter < widget.playerCount + 1) {
      safetyCounter++;

      final playerIndex =
          _matchController.currentRound.nextPlayerIndex!;

      try {
        final card = _chooseAiCard(playerIndex);

        await _animateCardToTable(playerIndex, card);
        await _playCardFeedback(card);
        _matchController.playCard(playerIndex, card);

        await _afterCardPlayed();

        if (!mounted || _finished) return;
      } catch (e) {
        if (mounted) {
          setState(() => _error = 'AI play error: $e');
        }
        return;
      }
    }
  }

  Future<void> _afterCardPlayed() async {
    final round = _matchController.currentRound;

    if (round.trickEngine.isComplete) {
      // Hold the completed trick on the table before advancing to the next one.
      final completedPlays = List<TrickPlay>.from(round.trickEngine.plays);
      final winnerPreview = round.trickEngine.winnerIndex;
      setState(() {
        _revealedTrickPlays = completedPlays;
        _collectingTrickWinner = null;
        _status = 'TRICK COMPLETE • ${_playerNames[winnerPreview]} wins the trick';
      });
      if (_soundEnabled) await _audio.play('trick_win');
      await HapticFeedback.heavyImpact();
      // Briefly show the completed trick, then animate every card into
      // the winning player's seat before the next trick is dealt.
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() {
        _collectingTrickWinner = winnerPreview;
      });
      await Future.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;

      final winner = _matchController.completeTrick();
      _trickNumber = round.completedTricks;

      setState(() {
        _status = 'Trick $_trickNumber won by ${_playerNames[winner]}.';
        _finished = round.isRoundEnded;
        _revealedTrickPlays = [];
        _collectingTrickWinner = null;
        _winCelebration = 'TRICK WON • ${_playerNames[winner]}';
      });

      // AI automatically makes a valid 16 call when eligible.
      final sixteen = round.sixteenCallEngine;

      if (!_finished &&
          winner != 0 &&
          sixteen != null &&
          sixteen.canCall &&
          sixteen.lastTrickWinnerIndex == winner) {
        try {
          _matchController.call16(callerPlayerIndex: winner);

          setState(() {
            _status =
                'AI called 16! Their team must win every remaining trick.';
          });
        } catch (e) {
          setState(() => _error = 'AI 16 call error: $e');
        }
      }

      if (_finished) {
        if (_matchController.isMatchOver) {
          if (_soundEnabled) await _audio.play('match_win');
          await HapticFeedback.vibrate();
          if (mounted) setState(() => _winCelebration = 'MATCH CHAMPION!');
        } else {
          if (_soundEnabled) await _audio.play('round_win');
          await HapticFeedback.heavyImpact();
          if (mounted) setState(() => _winCelebration = 'ROUND WON!');
        }
        final score = _matchController.matchScoreEngine;

        setState(() {
          _status =
              'Round complete. Team A: ${score.teamAScore}  '
              'Team B: ${score.teamBScore}';
        });
      }
    } else {
      setState(() {
        final next = round.nextPlayerIndex;
        _status = next == null
            ? 'Round complete.'
            : '${_playerNames[next]} to play.';
      });
    }

    // Persist after every card so an unexpected app close does not discard
    // the latest turn. Save failures are surfaced without interrupting play.
    await _autoSaveGame();
    if (mounted && _winCelebration != null) {
      await Future.delayed(const Duration(milliseconds: 1150));
      if (mounted) setState(() => _winCelebration = null);
    }
  }

  Future<void> _autoSaveGame() async {
    try {
      await _matchController.saveGame(_saveService);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Auto-save failed: $e');
      }
    }
  }

  // ----------------------------------------------------------
  // 16 CALL
  // ----------------------------------------------------------

  bool get _humanCanCall16 {
    if (!_started || _finished) return false;

    final engine =
        _matchController.currentRound.sixteenCallEngine;

    return !_passed16 &&
        engine != null &&
        engine.canCall &&
        engine.lastTrickWinnerIndex == 0;
  }

  void _pass16() {
    if (!_humanCanCall16 || _busy) return;

    setState(() {
      _passed16 = true;
      _status = 'You passed the 16 Call. Continue playing normally.';
    });
  }

  Future<void> _call16() async {
    if (!_humanCanCall16 || _busy) return;

    try {
      _matchController.call16(callerPlayerIndex: 0);

      setState(() {
        _status =
            '16 CALL! Your team must win every remaining trick.';
      });

      await _runAiTurns();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  // ----------------------------------------------------------
  // SAVE
  // ----------------------------------------------------------

  Future<void> _saveGame() async {
    if (!_started) return;

    try {
      await _matchController.saveGame(_saveService);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match saved successfully.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Save failed: $e');
      }
    }
  }

  // ----------------------------------------------------------
  // NEXT ROUND
  // ----------------------------------------------------------

  Future<void> _nextRound() async {
    if (!_finished || _busy || _matchController.isMatchOver) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      setState(() => _isShuffling = true);
      _shuffleController.repeat(reverse: true);
      await _playShuffleSound();
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      _shuffleController.stop();
      setState(() => _isShuffling = false);

      final deck = loris_deck.LorisDeck.create(
        widget.playerCount == 4
            ? loris.PlayerCount.four
            : loris.PlayerCount.six,
        random: _random,
      );

      final newHands = _dealController.deal(
        deck: deck,
        playerCount: widget.playerCount,
        dealerIndex: _matchController.dealerIndex,
      );

      setState(() {
        _hands = newHands;
        _dealerIndex = _matchController.dealerIndex;

        _biddingController = null;

        _started = false;
        _finished = false;
        _passed16 = false;
        _isDealing = true;

        _trumpSuit = null;

        _trickNumber = 0;

        _status = 'Next round dealt. Bidding begins.';
      });

      await _animateDeal(_matchController.dealerIndex);
      if (!mounted) return;
      setState(() => _isDealing = false);
      _startBidding();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------

  String _suitName(loris.Suit suit) {
    switch (suit) {
      case loris.Suit.clubs:
        return 'Clubs';
      case loris.Suit.diamonds:
        return 'Diamonds';
      case loris.Suit.hearts:
        return 'Hearts';
      case loris.Suit.spades:
        return 'Spades';
    }
  }

  String _suitSymbol(loris.Suit? suit) {
    switch (suit) {
      case loris.Suit.clubs:
        return '♣';
      case loris.Suit.diamonds:
        return '♦';
      case loris.Suit.hearts:
        return '♥';
      case loris.Suit.spades:
        return '♠';
      case null:
        return '';
    }
  }

  String _cardName(loris.Card card) {
    if (card.isLoris) return 'LORIS';

    return '${card.displayName}${_suitSymbol(card.suit)}';
  }

  bool _isRedSuit(loris.Suit? suit) {
    return suit == loris.Suit.hearts ||
        suit == loris.Suit.diamonds;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final hands = _hands;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LORIS MATCH',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: LorisApp.blue,
        actions: [
          if (_started)
            IconButton(
              tooltip: 'Save match',
              onPressed: _saveGame,
              icon: const Icon(
                Icons.save,
                color: LorisApp.gold,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: hands == null
            ? _buildStartPanel()
            : _buildGamePanel(hands),
      ),
    );
  }

  // ----------------------------------------------------------
  // START PANEL
  // ----------------------------------------------------------

  Widget _buildStartPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 112,
              child: _isShuffling
                  ? AnimatedBuilder(
                      animation: _shuffleController,
                      builder: (context, child) {
                        final phase = _shuffleController.value * 2 * pi;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            for (var i = 0; i < 5; i++)
                              Transform.translate(
                                offset: Offset(
                                  sin(phase + i * .85) * 30,
                                  cos(phase + i * .85) * 9,
                                ),
                                child: Transform.rotate(
                                  angle: sin(phase + i * .85) * .20,
                                  child: Container(
                                    width: 48,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF315F9A), Color(0xFF102747)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(color: LorisApp.gold, width: 1.5),
                                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
                                    ),
                                    child: const Center(child: Icon(Icons.auto_awesome, color: LorisApp.gold, size: 18)),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  : const Icon(Icons.style, size: 76, color: LorisApp.gold),
            ),
            if (_isShuffling) ...[
              const SizedBox(height: 4),
              const Text('SHUFFLING THE DECK', style: TextStyle(color: LorisApp.gold, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w900)),
            ],
            const SizedBox(height: 20),
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
                  ? '1 Human + 3 AI'
                  : '1 Human + 5 AI',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              widget.playerCount == 4
                  ? 'Teams A - B - A - B'
                  : 'Teams A - B - A - B - A - B',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _startMatch,
                icon: const Icon(Icons.play_arrow),
                label: Text(_busy ? 'STARTING...' : 'START MATCH'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
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

  // ----------------------------------------------------------
  // MAIN GAME PANEL
  // ----------------------------------------------------------

  Widget _buildGamePanel(List<List<loris.Card>> hands) {
    final round = _started ? _matchController.currentRound : null;
    final bidding = _biddingController;
    final currentPlayer = round?.nextPlayerIndex;
    final plays = round?.trickEngine.plays ?? const <TrickPlay>[];
    final legalHumanCards = _started && !_finished && currentPlayer == 0
        ? round!.trickEngine.legalCardsFor(0)
        : const <loris.Card>[];

    // Bidding remains scrollable; the live match itself is a fixed,
    // screen-fitted layout so the table and all eight cards stay visible.
    if (!_started) {
      return Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildScoreBoard(),
                const SizedBox(height: 10),
                _infoStrip('DEALER', _dealerIndex == null
                    ? '-'
                    : '${_playerAvatars[_dealerIndex!]} ${_playerNames[_dealerIndex!]}'),
                _infoStrip('STATUS', _status),
                if (_error != null) _buildErrorBanner(),
                _buildBiddingHand(hands[0]),
                _buildBiddingTable(bidding),
                if (bidding != null && bidding.isHumanTurn && !bidding.isComplete)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _humanBid,
                      child: const Text('MAKE YOUR BID'),
                    ),
                  ),
              ],
            ),
          ),
          if (_isShuffling) Positioned.fill(child: _buildShuffleOverlay()),
          if (_isDealing) Positioned.fill(child: _buildDealAnimation()),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final handCount = hands[0].length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
          child: Column(
            children: [
              _buildTurnBanner(currentPlayer),
              _buildCompactMatchHeader(),
              if (_error != null) _buildErrorBanner(),
              Expanded(
                child: _buildTableSurface(
                  _revealedTrickPlays.isNotEmpty ? _revealedTrickPlays : plays,
                  currentPlayer,
                  hands.map((hand) => hand.length).toList(),
                ),
              ),
              if (_humanCanCall16)
                SizedBox(
                  height: 38,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy ? null : _call16,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LorisApp.gold,
                            foregroundColor: LorisApp.navy,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('CALL 16', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _pass16,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('PASS', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_finished)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _matchController.isMatchOver
                            ? 'MATCH FINISHED • ${_matchController.matchWinner.name.toUpperCase()}'
                            : 'ROUND FINISHED',
                        style: const TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      if (!_matchController.isMatchOver) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _busy ? null : _nextRound,
                          child: const Text('NEXT ROUND'),
                        ),
                      ],
                    ],
                  ),
                ),
              SizedBox(
                height: constraints.maxHeight < 650 ? 112 : 124,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'YOUR HAND',
                          style: TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          '$handCount CARDS',
                          style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                        ),
                        if (_busy && !_finished) ...[
                          const SizedBox(width: 8),
                          const SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 1.5, color: LorisApp.gold)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, handConstraints) {
                          const cardWidth = 62.0;
                          final overlap = handCount <= 1
                              ? cardWidth
                              : ((handConstraints.maxWidth - cardWidth) / (handCount - 1)).clamp(24.0, 43.0);
                          return SizedBox(
                            width: handConstraints.maxWidth,
                            child: Stack(
                              alignment: Alignment.bottomLeft,
                              clipBehavior: Clip.none,
                              children: [
                                for (var index = 0; index < handCount; index++)
                                  Positioned(
                                    left: index * overlap,
                                    bottom: 1,
                                    child: Builder(
                                      builder: (context) {
                                        final card = hands[0][index];
                                        final playable = !_finished &&
                                            !_busy &&
                                            currentPlayer == 0 &&
                                            legalHumanCards.contains(card);
                                        final middle = (handCount - 1) / 2;
                                        final angle = (index - middle) * .025;
                                        return GestureDetector(
                                          onTap: playable ? () => _playHumanCard(card) : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            curve: Curves.easeOut,
                                            transform: Matrix4.identity()
                                              ..translateByDouble(0, playable ? -7 : 0, 0, 1)
                                              ..rotateZ(angle),
                                            transformAlignment: Alignment.bottomCenter,
                                            child: _buildCard(card, enabled: playable),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactMatchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172F52), Color(0xFF091A32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: LorisApp.gold.withValues(alpha: .75), width: 1.1),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 9, offset: Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _compactScore('TEAM A', _matchController.matchScoreEngine.teamAScore)),
              Container(width: 1, height: 30, color: LorisApp.gold.withValues(alpha: .5)),
              Expanded(child: _compactScore('TEAM B', _matchController.matchScoreEngine.teamBScore)),
              Container(width: 1, height: 30, color: LorisApp.gold.withValues(alpha: .5)),
              Column(
                children: [
                  const Text('TRUMP', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                  Text(
                    _trumpSuit == null ? '—' : _suitSymbol(_trumpSuit),
                    style: TextStyle(color: _trumpSuit != null && _isRedSuit(_trumpSuit) ? const Color(0xFFFF737D) : LorisApp.gold, fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.circle, color: Color(0xFF64DDA8), size: 7),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
              if (_dealerIndex != null)
                Text(
                  'DEALER  ${_playerNames[_dealerIndex!]}',
                  style: const TextStyle(color: LorisApp.gold, fontSize: 8, fontWeight: FontWeight.w900),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnBanner(int? currentPlayer) {
    final isHuman = currentPlayer == 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFE7A0), Color(0xFFB77A2D)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 7, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(isHuman ? Icons.touch_app_rounded : Icons.hourglass_top_rounded,
              color: const Color(0xFF2B1B0C), size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              currentPlayer == null
                  ? 'ROUND COMPLETE'
                  : 'NOW PLAYING  •  ${_playerNames[currentPlayer]}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF2B1B0C), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: .8),
            ),
          ),
          if (isHuman)
            const Text('YOUR TURN', style: TextStyle(color: Color(0xFF2B1B0C), fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _compactScore(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: LorisApp.gold, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text('$value', style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.05, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withValues(alpha: .45)),
      ),
      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
    );
  }

  // ----------------------------------------------------------
  // SCORE BOARD
  // ----------------------------------------------------------

  Widget _buildScoreBoard() {
    final score = _matchController.matchScoreEngine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: LorisApp.blue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LorisApp.gold.withValues(alpha: .7),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreItem('TEAM A', score.teamAScore),
          Container(
            width: 1,
            height: 40,
            color: LorisApp.gold,
          ),
          _scoreItem('TEAM B', score.teamBScore),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: LorisApp.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // INFO STRIPS
  // ----------------------------------------------------------

  Widget _infoStrip(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: LorisApp.blue.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LorisApp.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // BIDDING HAND AND DEAL ANIMATION
  // ----------------------------------------------------------

  Widget _buildBiddingHand(List<loris.Card> hand) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LorisApp.navy.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LorisApp.gold, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR HAND • ${hand.length} CARDS',
            style: const TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 8,
            children: hand.map((card) => _buildCard(card, compact: true)).toList(),
          ),
        ],
      ),
    );
  }

  Alignment _dealSeatAlignment(int playerIndex) {
    final seats = widget.playerCount == 4
        ? const <Alignment>[
            Alignment(0, .78),
            Alignment(-.86, 0),
            Alignment(0, -.78),
            Alignment(.86, 0),
          ]
        : const <Alignment>[
            Alignment(0, .82),
            Alignment(-.86, .48),
            Alignment(-.86, -.48),
            Alignment(0, -.82),
            Alignment(.86, -.48),
            Alignment(.86, .48),
          ];
    return seats[playerIndex];
  }

  Widget _dealCardBack() {
    return Container(
      width: 48,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [Color(0xFF315F9A), Color(0xFF102747)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: LorisApp.gold, width: 1.6),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(2, 5))],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, color: LorisApp.gold, size: 22),
      ),
    );
  }

  Widget _buildShuffleOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: .88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _shuffleController,
              builder: (context, child) {
                final phase = _shuffleController.value * 2 * pi;
                return SizedBox(
                  width: 170,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Transform.translate(
                          offset: Offset(sin(phase + i * .85) * 34, cos(phase + i * .85) * 10),
                          child: Transform.rotate(
                            angle: sin(phase + i * .85) * .24,
                            child: _dealCardBack(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('SHUFFLING THE DECK',
              style: TextStyle(color: LorisApp.gold, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildDealAnimation() {
    final target = _dealTargetPlayer;
    return ColoredBox(
      color: Colors.black.withValues(alpha: .88),
      child: Stack(
        children: [
          Positioned(
            top: 34,
            left: 12,
            right: 12,
            child: Column(
              children: [
                const Text('DEALING CARDS',
                  style: TextStyle(color: LorisApp.gold, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 6),
                Text('BATCH ${_dealBatch + 1} OF 2  •  CARD $_dealCardNumber OF 4',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 24,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: List.generate(widget.playerCount, (index) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_playerAvatars[index], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 3),
                  Text(_playerNames[index], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              )),
            ),
          ),
          AnimatedAlign(
            alignment: target == null ? Alignment.center : _dealSeatAlignment(target),
            duration: target == null ? Duration.zero : const Duration(milliseconds: 115),
            curve: Curves.easeOutCubic,
            child: _dealCardBack(),
          ),
          if (target != null)
            Positioned(
              top: 86,
              left: 12,
              right: 12,
              child: Text('TO ${_playerNames[target]}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
        ],
      ),
    );
  }

  Future<void> _animateDeal(int dealerIndex) async {
    final firstPlayer = (dealerIndex + 1) % widget.playerCount;
    for (var batch = 0; batch < 2; batch++) {
      for (var cardNumber = 0; cardNumber < 4; cardNumber++) {
        for (var offset = 0; offset < widget.playerCount; offset++) {
          if (!mounted) return;
          final player = (firstPlayer + offset) % widget.playerCount;
          setState(() {
            _dealBatch = batch;
            _dealCardNumber = cardNumber + 1;
            _dealTargetPlayer = null;
          });
          await Future.delayed(const Duration(milliseconds: 18));
          if (!mounted) return;
          setState(() => _dealTargetPlayer = player);
          await Future.delayed(const Duration(milliseconds: 115));
          if (!mounted) return;
          setState(() => _dealTargetPlayer = null);
          await Future.delayed(const Duration(milliseconds: 22));
        }
      }
    }
  }

  // ----------------------------------------------------------
  // BIDDING TABLE
  // ----------------------------------------------------------

  Widget _buildBiddingTable(
    BiddingRoundController? bidding,
  ) {
    if (bidding == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LorisApp.tableGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LorisApp.gold,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'BIDDING TABLE',
            style: TextStyle(
              color: LorisApp.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.playerCount, (index) {
              final records = bidding.history
                  .where((record) => record.playerIndex == index)
                  .toList();

              final bidText = records.isEmpty
                  ? '—'
                  : records.last.amount == null
                      ? 'PASS'
                      : '${records.last.amount}';

              final isHuman = index == 0;

              final isHighest =
                  bidding.highestBidder == index;

              return Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: isHighest
                          ? LorisApp.gold
                          : isHuman
                              ? Colors.white
                              : LorisApp.navy,
                      foregroundColor: isHighest || isHuman
                          ? LorisApp.navy
                          : Colors.white,
                      child: LorisPortraitAvatar(
                        variant: index,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      bidText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: LorisApp.navy.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'HIGHEST BID: ${bidding.highestBid ?? "-"}'
              '${bidding.highestBidder == null ? "" : "  •  ${_playerNames[bidding.highestBidder!]}"}',
              style: const TextStyle(
                color: LorisApp.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // PLAYING TABLE
  // ----------------------------------------------------------

  Widget _buildTableSurface(
    List<TrickPlay> plays,
    int? currentPlayer,
    List<int> handCounts,
  ) {
    final seatAlignments = widget.playerCount == 4
        ? const <Alignment>[
            Alignment(0, .82),
            Alignment(-.88, 0),
            Alignment(0, -.84),
            Alignment(.88, 0),
          ]
        : const <Alignment>[
            Alignment(0, .85),
            Alignment(-.87, .53),
            Alignment(-.87, -.53),
            Alignment(0, -.85),
            Alignment(.87, -.53),
            Alignment(.87, .53),
          ];

    final trickCollectionTargets = widget.playerCount == 4
        ? const <Alignment>[
            Alignment(0, .63),
            Alignment(-.64, 0),
            Alignment(0, -.63),
            Alignment(.64, 0),
          ]
        : const <Alignment>[
            Alignment(0, .63),
            Alignment(-.62, .38),
            Alignment(-.62, -.38),
            Alignment(0, -.63),
            Alignment(.62, -.38),
            Alignment(.62, .38),
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableHeight = constraints.maxHeight;
        final avatarSize = widget.playerCount == 6 ? 34.0 : 38.0;
        final seatWidth = widget.playerCount == 6 ? 68.0 : 76.0;
        final centerWidth = (constraints.maxWidth * .46).clamp(126.0, 166.0);
        final centerHeight = (tableHeight * .32).clamp(94.0, 126.0);

        return Container(
          width: double.infinity,
          height: tableHeight,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(150),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE9A3), Color(0xFF9A642A), Color(0xFFFFD36A), Color(0xFF57351D)],
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 9)),
              BoxShadow(color: Color(0x995B3518), blurRadius: 0, spreadRadius: 1),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(145),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B6048), Color(0xFF064331), Color(0xFF022A22)],
              ),
              border: Border.all(color: const Color(0xFFFFE6A0), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(130),
                        border: Border.all(color: const Color(0x55E8D09A), width: 1),
                        gradient: const RadialGradient(
                          center: Alignment(0, -.25),
                          radius: 1.15,
                          colors: [Color(0xFF16795A), Color(0xFF032D25)],
                        ),
                      ),
                    ),
                  ),
                ),
                for (var index = 0; index < widget.playerCount; index++)
                  Align(
                    alignment: seatAlignments[index],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      width: seatWidth,
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _collectingTrickWinner == index
                              ? const [Color(0xFFFFE7A0), Color(0xFFB77A2D), Color(0xFF63351C)]
                              : currentPlayer == index
                                  ? const [Color(0xFF314F70), Color(0xFF152A45)]
                                  : const [Color(0xFF263B55), Color(0xFF0A1729)],
                        ),
                        border: Border.all(
                          color: _collectingTrickWinner == index || currentPlayer == index
                              ? const Color(0xFFFFE6A0)
                              : const Color(0xFF9B855C),
                          width: _collectingTrickWinner == index ? 2.2 : currentPlayer == index ? 1.6 : .8,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 8, offset: const Offset(0, 4)),
                          if (_collectingTrickWinner == index)
                            const BoxShadow(color: Color(0x99FFD76B), blurRadius: 18, spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFFFF4C5), Color(0xFFB4772E), Color(0xFFFFE5A0)]),
                              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 5, offset: Offset(0, 2))],
                            ),
                            child: LorisPortraitAvatar(
                              variant: index,
                              size: avatarSize,
                              highlighted: currentPlayer == index || _collectingTrickWinner == index,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _playerNames[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'TEAM ${index.isEven ? "A" : "B"}',
                            style: const TextStyle(color: Color(0xFFFFD978), fontSize: 7, fontWeight: FontWeight.bold),
                          ),
                          if (currentPlayer == index)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE7A0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                index == 0 ? 'YOUR TURN' : 'PLAYING',
                                style: const TextStyle(color: Color(0xFF2B1B0C), fontSize: 6, fontWeight: FontWeight.w900),
                              ),
                            ),
                          if (index != 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var back = 0; back < (handCounts[index] > 0 ? 3 : 0); back++)
                                    Transform.translate(
                                      offset: Offset(back * -3.0, 0),
                                      child: Container(
                                        width: 7,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(1.5),
                                          gradient: const LinearGradient(colors: [Color(0xFF315F9A), Color(0xFF102747)]),
                                          border: Border.all(color: const Color(0xFFFFD978), width: .5),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 3),
                                  Text('${handCounts[index]}', style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          if (_collectingTrickWinner == index)
                            const Text('TRICK WON', style: TextStyle(color: Color(0xFFFFE7A0), fontSize: 7, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                Container(
                  width: centerWidth,
                  height: centerHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xAA0B7253), Color(0xCC022D25)],
                    ),
                    border: Border.all(color: const Color(0x77F5D78C), width: 1),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        currentPlayer == null
                            ? 'ROUND COMPLETE'
                            : 'NOW PLAYING • ${_playerNames[currentPlayer]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFFFE39A), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: .7),
                      ),
                      if (plays.isEmpty)
                        const Text('PLAY A CARD', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold))
                      else
                        const SizedBox(height: 1),
                      Text(
                        '${plays.length} / ${widget.playerCount} CARDS',
                        style: const TextStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < plays.length; i++)
                  AnimatedAlign(
                    key: ValueKey('trick-${plays[i].playerIndex}-${plays[i].card.hashCode}'),
                    alignment: _collectingTrickWinner == null
                        ? Alignment(
                            -.38 + (i % 3) * .38,
                            -.25 + (i ~/ 3) * .50,
                          )
                        : trickCollectionTargets[_collectingTrickWinner!],
                    duration: Duration(milliseconds: _collectingTrickWinner == null ? 220 : 520),
                    curve: _collectingTrickWinner == null ? Curves.easeOutBack : Curves.easeInCubic,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: .78, end: _collectingTrickWinner == null ? 1 : .42),
                      duration: Duration(milliseconds: _collectingTrickWinner == null ? 220 : 520),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: _buildCard(plays[i].card, compact: true),
                    ),
                  ),
                if (_flyingCard != null && _flyingFromPlayer != null)
                  AnimatedAlign(
                    alignment: _flightStarted
                        ? Alignment.center
                        : seatAlignments[_flyingFromPlayer!],
                    duration: Duration(milliseconds: _flightStarted ? 520 : 1),
                    curve: Curves.easeInOutCubic,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: _flightStarted ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeInOutCubic,
                      builder: (context, progress, child) {
                        final transform = Matrix4.identity()
                          ..setEntry(3, 2, 0.0014)
                          ..rotateX((1 - progress) * .72)
                          ..rotateY((1 - progress) * -.88)
                          ..rotateZ((1 - progress) * -.34)
                          ..scaleByDouble(
                            .70 + (progress * .30),
                            .70 + (progress * .30),
                            1.0,
                            1.0,
                          );
                        return Transform(
                          alignment: Alignment.center,
                          transform: transform,
                          child: child,
                        );
                      },
                      child: _buildCard(_flyingCard!, compact: true),
                    ),
                  ),
                if (_playEffect != null)
                  Positioned(
                    top: tableHeight * .34,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _playEffect == 'LORIS!'
                              ? const Color(0xFF6C3BC1).withValues(alpha: .94)
                              : const Color(0xFFD6B15E).withValues(alpha: .96),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, spreadRadius: 2)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Text(
                            _playEffect!,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_winCelebration != null)
                  Positioned(
                    top: tableHeight * .27,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: .65, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFE9A3), Color(0xFFB77A2D)]),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white, width: 1),
                              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 18, spreadRadius: 2)],
                            ),
                            child: Text(
                              _winCelebration!,
                              style: const TextStyle(color: Color(0xFF27190B), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_trumpSuit != null)
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE8A0), Color(0xFFB77B32)]),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        'TRUMP  ${_suitSymbol(_trumpSuit)}',
                        style: const TextStyle(color: Color(0xFF2B1B0C), fontWeight: FontWeight.w900, fontSize: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // CARD WIDGET
  // ----------------------------------------------------------

  Widget _buildCard(
    loris.Card card, {
    bool enabled = false,
    bool compact = false,
  }) {
    final isRed = _isRedSuit(card.suit);
    final ink = card.isLoris ? const Color(0xFF17243B) : isRed ? const Color(0xFFB51F32) : const Color(0xFF17202B);
    final width = compact ? 48.0 : 62.0;
    final height = compact ? 68.0 : 92.0;

    Widget corner({required bool upsideDown}) {
      return Transform.rotate(
        angle: upsideDown ? 3.1415926535 : 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.isLoris ? '★' : card.displayName,
              style: TextStyle(color: ink, fontSize: compact ? 11 : 15, height: 1, fontWeight: FontWeight.w900)),
            Text(card.isLoris ? '♛' : _suitSymbol(card.suit),
              style: TextStyle(color: ink, fontSize: compact ? 10 : 13, height: 1.05, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(compact ? 3 : 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 5 : 7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: card.isLoris
              ? const [Color(0xFFFFF1B5), Color(0xFFE6B94E), Color(0xFFFFE9A0)]
              : const [Colors.white, Color(0xFFF8F7F1), Color(0xFFE5E2D9)],
        ),
        border: Border.all(color: enabled ? const Color(0xFFFFD76B) : const Color(0xFFD1C9B8), width: enabled ? 2.2 : .8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: enabled ? 9 : 5, offset: const Offset(2, 4)),
          if (enabled) const BoxShadow(color: Color(0x88FFD76B), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: corner(upsideDown: false)),
          Align(alignment: Alignment.bottomRight, child: corner(upsideDown: true)),
          Center(
            child: card.isLoris
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: ink, size: compact ? 19 : 25),
                      if (!compact) Text('LORIS', style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  )
                : Text(_suitSymbol(card.suit),
                    style: TextStyle(color: ink, fontSize: compact ? 22 : 31, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Color(0x22000000), blurRadius: 1, offset: Offset(1, 1))])),
          ),
        ],
      ),
    );
  }

}
