import 'dart:math';
import 'package:flutter/services.dart';
import 'game/engine/loris_audio_service.dart';
import 'game/engine/game_settings_service.dart';
import 'package:material_ui/material_ui.dart';

import 'game/models/loris_card.dart' as loris;
import 'game/models/loris_deck.dart' as loris_deck;

import 'game/engine/sixteen_call_engine.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LorisApp());
}

// ============================================================
// APP
// ============================================================

class LorisApp extends StatelessWidget {
  const LorisApp({super.key});

  static const Color navy = Color(0xFF5B351F);
  static const Color blue = Color(0xFF8A552E);
  static const Color gold = Color(0xFFFFD36A);
  static const Color tableGreen = Color(0xFF075239);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LORIS – The Ultimate Card Game',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF4DC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.light,
          primary: const Color(0xFF9B622E),
          onPrimary: Colors.white,
          surface: const Color(0xFFFFE8B2),
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
          backgroundColor: const Color(0xFFFFF1D4),
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
        builder: (_) => GameScreen(playerCount: playerCount, soundEnabled: _soundEnabled),
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
            soundEnabled: _soundEnabled,
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
                      'also hold, or chooses the LORIS Joker from their own '
                      'hand for Joker mode. A teammate may reveal one eligible '
                      'suit card for a normal trump selection.',
                ),
                _RuleSection(
                  title: 'PLAYING TRICKS',
                  body: 'You must follow the suit led if you have a card of that suit. '
                      'If you are void in the led suit, you may play any card. '
                      'Trumping and overtrumping are optional. The LORIS card '
                      'is the Joker and beats every card. In Joker mode there is '
                      'no trump suit; the highest rank wins across all suits.',
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
                  body: 'A CALL 16 opportunity appears immediately when the '
                      'bidding team reaches its bid and wins that trick, but only '
                      'if the opponents have won zero tricks in the round. The '
                      'last-trick winner on the bidding team may CALL 16 or PASS. '
                      'The choice is available only once per round. After CALL 16, '
                      'the team must win every remaining trick; losing even one '
                      'gives that team -16 and the opponents +16. If the team '
                      'passes, normal scoring continues.',
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
                    'Soft card-swish and game sounds follow this setting.',
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
              Color(0xFFFFF7E8),
              Color(0xFFFFE6B0),
              Color(0xFFE9BD70),
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
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE8A6), Color(0xFFB9772E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Color(0xFFFFF5D8), width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x66834B1C), blurRadius: 22, offset: Offset(0, 9))],
                    ),
                    child: const Icon(Icons.auto_awesome, size: 68, color: Color(0xFF6B351D)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'LORIS',
                    style: TextStyle(
                      color: Color(0xFF70401F),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'THE ULTIMATE CARD GAME',
                    style: TextStyle(
                      color: Color(0xFF5B351F),
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
                      color: Color(0xFF805B35),
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
                foregroundColor: const Color(0xFF5B351F),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B351F),
                side: const BorderSide(color: Color(0xFF8A552E), width: 1.4),
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
    this.soundEnabled = true,
  });

  final int playerCount;
  final GameStateSnapshot? savedSnapshot;
  final bool soundEnabled;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final GameSaveService _saveService = GameSaveService();
  final LorisAudioService _audio = LorisAudioService();
  final Random _random = Random();

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
  late final List<String> _playerNames;

  late final DealController _dealController;
  late final GameMatchController _matchController;

  List<List<loris.Card>>? _hands;

  BiddingRoundController? _biddingController;

  loris.Suit? _trumpSuit;
  loris.Card? _trumpCard;

  bool _started = false;
  bool _finished = false;
  bool _busy = false;
  bool _isShuffling = false;
  bool _showSixteenCallEffect = false;
  List<loris.Card>? _dealerDrawnCards;
  int _dealerRevealVisibleCount = 0;
  int _dealerFirstPlayerIndex = 0;
  bool _isDealingCards = false;
  bool _dealerDrawActive = false;
  int _dealtCardCount = 0;
  bool _awaitingTrumpSelection = false;
  int? _pendingTrumpBidder;
  List<MapEntry<int, loris.Card>> _pendingTrumpChoices = [];
  late final AnimationController _shuffleController;

  String _status = 'Press START MATCH to begin.';
  String? _error;

  int? _dealerIndex;

  int _trickNumber = 0;
  List<TrickPlay> _revealedTrickPlays = [];
  List<TrickPlay> _lastTrickPlays = [];
  int? _lastTrickWinner;
  int? _collectingTrickWinner;
  loris.Card? _flyingCard;
  int? _flyingFromPlayer;
  bool _flightStarted = false;
  String? _playEffect;
  String? _winCelebration;
  
  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

    final shuffledNames = List<String>.from(_namePool)..shuffle(_random);
    _playerNames = [
      'YOU',
      ...shuffledNames.take(widget.playerCount - 1),
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

  @override
  void dispose() {
    _shuffleController.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _animateCardToTable(int playerIndex, loris.Card card) async {
    if (!mounted) return;
    setState(() {
      if (_revealedTrickPlays.isNotEmpty) {
        _revealedTrickPlays = [];
        _collectingTrickWinner = null;
      }
      _flyingCard = card;
      _flyingFromPlayer = playerIndex;
      _flightStarted = true;
      _playEffect = card.isLoris ? 'LORIS!' : null;
    });
    await Future.delayed(const Duration(milliseconds: 560));
    if (!mounted) return;
    await _playCardFeedback(card);
    await Future.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    setState(() {
      _flyingCard = null;
      _flyingFromPlayer = null;
      _flightStarted = false;
    });
    if (card.isLoris) {
      await Future.delayed(const Duration(milliseconds: 760));
      if (!mounted) return;
      setState(() => _playEffect = null);
    }
  }

  Future<void> _playSound(String effect) async {
    if (widget.soundEnabled) await _audio.play(effect);
  }

  Future<void> _playCardFeedback(loris.Card card) async {
    if (card.isLoris) {
      await _playSound('loris');
      await HapticFeedback.heavyImpact();
    } else {
      await _playSound('card_place');
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _playShuffleSound() async {
    await _playSound('shuffle');
    await HapticFeedback.lightImpact();
  }

  Future<void> _triggerSixteenCallEffect() async {
    if (!mounted) return;
    setState(() => _showSixteenCallEffect = true);
    await _playSound('loris');
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 220));
    await _playSound('trump');
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 1450));
    if (mounted) setState(() => _showSixteenCallEffect = false);
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
      _trumpCard = _trumpSuit == null
          ? _hands!.expand((hand) => hand).where((card) => card.isLoris).firstOrNull
          : null;

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
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      _shuffleController.stop();
      setState(() => _isShuffling = false);
      final deck = loris_deck.LorisDeck.create(
        widget.playerCount == 4 ? loris.PlayerCount.four : loris.PlayerCount.six,
        random: _random,
      );
      final dealerSelection = _matchController.selectInitialDealer(
        deck: deck,
        playerCount: widget.playerCount,
        random: _random,
      );
      _dealerFirstPlayerIndex =
          (dealerSelection.dealerIndex - (dealerSelection.drawnCards.length - 1)) %
              widget.playerCount;
      setState(() {
        _dealerDrawnCards = dealerSelection.drawnCards;
        _dealerRevealVisibleCount = 0;
        _dealerDrawActive = true;
        _dealerIndex = _dealerFirstPlayerIndex;
        _status = '${_playerNames[_dealerFirstPlayerIndex]} starts the random dealer draw';
      });
      for (var i = 0; i < dealerSelection.drawnCards.length; i++) {
        await Future.delayed(const Duration(milliseconds: 560));
        if (!mounted) return;
        setState(() => _dealerRevealVisibleCount = i + 1);
        final card = dealerSelection.drawnCards[i];
        if (!card.isLoris && card.rank == 11) {
          await HapticFeedback.heavyImpact();
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _dealerDrawActive = false;
        _dealerIndex = dealerSelection.dealerIndex;
        _status = 'JACK FOUND • ${_playerNames[dealerSelection.dealerIndex]} is the dealer';
      });
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      final dealtHands = _dealController.deal(
        deck: dealerSelection.shuffledDeck,
        playerCount: widget.playerCount,
        dealerIndex: dealerSelection.dealerIndex,
      );
      setState(() {
        _dealerDrawnCards = null;
        _dealerDrawActive = false;
        _hands = dealtHands;
        _isDealingCards = true;
        _dealtCardCount = 0;
        _status = '${_playerNames[dealerSelection.dealerIndex]} is dealing 8 cards to each player';
      });
      final totalCards = widget.playerCount * 8;
      for (var dealt = 1; dealt <= totalCards; dealt++) {
        await Future.delayed(const Duration(milliseconds: 90));
        if (!mounted) return;
        setState(() => _dealtCardCount = dealt);
      }
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _isDealingCards = false;
        _status = 'Cards dealt. Bidding begins.';
      });
      _startBidding();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
        _trumpCard = null;

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

  Future<void> _humanBid(int? selectedBid) async {
    final bidding = _biddingController;
    if (bidding == null || !bidding.isHumanTurn || bidding.isComplete || _busy) return;
    final highestBid = bidding.highestBid ?? 3;
    if (selectedBid != null && selectedBid <= highestBid) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      bidding.submitHumanBid(selectedBid);
      setState(() {
        _status = bidding.isComplete
            ? 'Bidding complete.'
            : bidding.isHumanTurn
                ? 'Your turn to bid.'
                : 'AI players are bidding.';
      });
      if (bidding.isComplete) await _finishBidding();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
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
    final choices = <MapEntry<int, loris.Card>>[];
    for (final card in hands[bidder]) {
      if (!card.isLoris && card.suit != null) {
        choices.add(MapEntry(bidder, card));
      }
    }

    // Always show the Joker in the trump-selection interface. If the
    // bidder does not hold it, render it disabled rather than selectable.
    final heldJoker = hands[bidder].where((card) => card.isLoris).firstOrNull;
    final lowestRank = widget.playerCount == 4 ? 7 : 3;
    choices.add(MapEntry(
      bidder,
      heldJoker ?? loris.Card.loris(replacesRank: lowestRank),
    ));
    for (var player = 0; player < hands.length; player++) {
      if (player == bidder || player % 2 != bidder % 2) continue;
      for (final card in hands[player]) {
        if (!card.isLoris && card.suit != null &&
            hands[bidder].any((own) => own.suit == card.suit)) {
          choices.add(MapEntry(player, card));
        }
      }
    }
    setState(() {
      _pendingTrumpBidder = bidder;
      _pendingTrumpChoices = choices;
      _awaitingTrumpSelection = true;
      _status = 'Choose a suit card or the LORIS Joker.';
    });
  }

  Future<void> _chooseAiTrump(int bidder) async {
    final hands = _hands;

    if (hands == null) return;

    final joker = hands[bidder].where((card) => card.isLoris).firstOrNull;
    if (joker != null) {
      await _applyTrump(bidder, bidder, joker);
      return;
    }

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
      setState(() {
        _awaitingTrumpSelection = false;
        _pendingTrumpBidder = null;
        _pendingTrumpChoices = [];
      });
      final result = TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: bidder,
        highestBidderIndex: bidding.highestBidder!,
        cardOwnerIndex: cardOwner,
        selectedCard: selectedCard,
      );

      _trumpSuit = result.trumpSuit;
      _trumpCard = selectedCard;

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
          _trumpCard = null;
          _started = false;

          _status = 'Redeal required. Same dealer remains.';
        });

        _startBidding();
        return;
      }

      final selectedTrump = trump;
      final selectedBid = bidding.highestBid;
      final selectedBidder = bidding.highestBidder;

      if ((selectedTrump == null && _trumpCard?.isLoris != true) ||
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

        _status = selectedTrump == null
            ? 'Round started. LORIS JOKER mode — highest card wins.'
            : 'Round started. ${_suitName(selectedTrump)} is trump.';
      });

      await _runAiTurns();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  // ----------------------------------------------------------
  // CARD PLAY
  // ----------------------------------------------------------

  loris.Card _chooseAiCard(int playerIndex) {
    final engine = _matchController.currentRound.trickEngine;
    final hand = engine.hands[playerIndex];

    if (hand.isEmpty) {
      throw StateError('AI player has no cards.');
    }

    final legalCards = engine.legalCardsFor(playerIndex);
    if (legalCards.length == 1) return legalCards.first;

    int winningPlayer(List<TrickPlay> trick) {
      final lorisPlay = trick.where((play) => play.card.isLoris);
      if (lorisPlay.isNotEmpty) return lorisPlay.first.playerIndex;

      if (engine.trumpSuit == null) {
        final allCards = List<TrickPlay>.from(trick)
          ..sort((a, b) =>
              (b.card.rank ?? 0).compareTo(a.card.rank ?? 0));
        return allCards.first.playerIndex;
      }

      final firstCard = trick.first.card;
      final ledSuit = firstCard.isLoris
          ? loris.Suit.spades
          : firstCard.suit;
      final trumpPlays = trick
          .where((play) => !play.card.isLoris &&
              play.card.suit == engine.trumpSuit)
          .toList();
      final candidates = trumpPlays.isNotEmpty
          ? trumpPlays
          : trick.where((play) => play.card.suit == ledSuit).toList();

      candidates.sort((a, b) =>
          (b.card.rank ?? 0).compareTo(a.card.rank ?? 0));
      return candidates.first.playerIndex;
    }

    int compareCardCost(loris.Card a, loris.Card b) {
      if (a.isLoris) return b.isLoris ? 0 : 1;
      if (b.isLoris) return -1;
      return (a.rank ?? 0).compareTo(b.rank ?? 0);
    }

    final nonLoris = legalCards.where((card) => !card.isLoris).toList()
      ..sort(compareCardCost);
    final currentPlays = List<TrickPlay>.from(engine.plays);

    // When leading, keep the special card and high cards for later.
    if (currentPlays.isEmpty) {
      return nonLoris.isNotEmpty ? nonLoris.first : legalCards.first;
    }

    final currentWinner = winningPlayer(currentPlays);

    // Do not overtake a teammate who is already winning the trick.
    if (currentWinner % 2 == playerIndex % 2) {
      return nonLoris.isNotEmpty ? nonLoris.first : legalCards.first;
    }

    // If an opponent is winning, use the cheapest card that takes the lead.
    final winningCards = legalCards.where((card) {
      final simulated = [
        ...currentPlays,
        TrickPlay(playerIndex: playerIndex, card: card),
      ];
      return winningPlayer(simulated) == playerIndex;
    }).toList()
      ..sort(compareCardCost);

    if (winningCards.isNotEmpty) return winningCards.first;
    return nonLoris.isNotEmpty ? nonLoris.first : legalCards.first;
  }

  Future<void> _commitAndAnimateCard(int playerIndex, loris.Card card) async {
    // Commit first so the card leaves the player's hand as soon as it is tapped.
    // The table renderer temporarily hides the committed copy while its flight
    // animation is in progress, then reveals it in the player's directional slot.
    _matchController.playCard(playerIndex, card);
    await _animateCardToTable(playerIndex, card);
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
      await _commitAndAnimateCard(0, card);

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

        await _commitAndAnimateCard(playerIndex, card);

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
        _lastTrickPlays = completedPlays;
        _lastTrickWinner = winnerPreview;
        _collectingTrickWinner = null;
        _status = 'TRICK COMPLETE • ${_playerNames[winnerPreview]} wins the trick';
      });
      await _playSound('trick_win');
      await HapticFeedback.heavyImpact();
      // Briefly show the completed trick, then animate every card into
      // the winning player's seat before the next trick is dealt.
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        _collectingTrickWinner = winnerPreview;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      final winner = _matchController.completeTrick();
      _trickNumber = round.completedTricks;

      setState(() {
        _status = 'Trick $_trickNumber won by ${_playerNames[winner]}.';
        _finished = round.isRoundEnded;
        // Keep this completed trick on the table until the next trick starts.
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
          await _triggerSixteenCallEffect();
        } catch (e) {
          setState(() => _error = 'AI 16 call error: $e');
        }
      }

      if (_finished) {
        if (_matchController.isMatchOver) {
          await _playSound('match_win');
          await HapticFeedback.vibrate();
          if (mounted) setState(() => _winCelebration = 'MATCH CHAMPION!');
        } else {
          await _playSound('round_win');
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

    // Schedule (do not await) the next round. Waiting here would deadlock:
    // the human-turn handler releases _busy only after _runAiTurns returns.
    if (mounted && _finished && !_matchController.isMatchOver) {
      Future<void>.delayed(const Duration(milliseconds: 450), () async {
        while (mounted && _busy) {
          await Future.delayed(const Duration(milliseconds: 80));
        }
        if (mounted && _finished && !_matchController.isMatchOver) {
          await _nextRound();
        }
      });
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

    return engine != null &&
        engine.canCall &&
        engine.lastTrickWinnerIndex == 0;
  }

  Future<void> _call16() async {
    if (!_humanCanCall16 || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      _matchController.call16(callerPlayerIndex: 0);

      setState(() {
        _status =
            '16 CALL! Your team must win every remaining trick.';
      });

      await _triggerSixteenCallEffect();
      await _runAiTurns();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pass16() async {
    if (!_humanCanCall16 || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      _matchController.pass16(callerPlayerIndex: 0);
      setState(() {
        _status = '16 CALL PASSED. Continue playing normally.';
      });
      await _runAiTurns();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
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

        _trumpSuit = null;

        _trickNumber = 0;

        _status = 'Next round dealt. Bidding begins.';
      });

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

  bool _isFemalePlayer(String playerName) {
    const femaleNames = {
      'Jannat', 'Ayesha', 'Shima', 'Roma', 'Mitu',
      'Tania', 'Nusrat', 'Mim', 'Sumi', 'Rima', 'Nila',
      'Faria', 'Sumaiya', 'Tisha', 'Anika', 'Maliha',
    };
    return femaleNames.contains(playerName);
  }

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
    if (card.isLoris) return 'JOKER';

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
        child: hands != null
            ? _buildGamePanel(hands)
            : _dealerDrawnCards != null
                ? _buildGamePanel(
                    List<List<loris.Card>>.generate(
                      widget.playerCount,
                      (_) => <loris.Card>[],
                    ),
                  )
                : _buildStartPanel(),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final biddingPlayer = bidding != null && !bidding.isComplete
              ? bidding.engine.currentPlayerIndex
              : null;
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
            child: Column(
              children: [
                _buildCompactMatchHeader(),
                if (_error != null) _buildErrorBanner(),
                if (_isDealingCards)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: LinearProgressIndicator(
                      value: _dealtCardCount / (widget.playerCount * 8),
                      minHeight: 2,
                      backgroundColor: Colors.white24,
                      color: LorisApp.gold,
                    ),
                  ),
                Expanded(
                  child: _buildTableSurface(
                    const <TrickPlay>[],
                    biddingPlayer,
                    hands.map((hand) => hand.length).toList(),
                    dealerDrawCards: _dealerDrawnCards,
                    dealerDrawVisibleCount: _dealerRevealVisibleCount,
                    dealerDrawStartPlayer: _dealerFirstPlayerIndex,
                    dealerDrawActive: _dealerDrawActive,
                  ),
                ),
                if (!_isDealingCards && _awaitingTrumpSelection)
                  _buildTrumpSelectionControls(),
                if (!_isDealingCards && !_awaitingTrumpSelection &&
                    bidding != null && bidding.isHumanTurn && !bidding.isComplete)
                  _buildBiddingControls(bidding),
                SizedBox(
                  height: constraints.maxHeight < 650 ? 96 : 112,
                  child: _buildHandStrip(hands[0]),
                ),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final handCount = hands[0].length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
          child: Column(
            children: [
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
                  height: 42,
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
                            foregroundColor: LorisApp.gold,
                            side: const BorderSide(color: LorisApp.gold, width: 1.5),
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
                                        final card = _sortedHand(hands[0])[index];
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

  Widget _buildBiddingControls(BiddingRoundController bidding) {
    final highest = bidding.highestBid ?? 3;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF4B1821),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LorisApp.gold, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'YOUR BID  •  HIGHEST: ${bidding.highestBid ?? "-"}',
            style: const TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            bidding.history.isEmpty
                ? 'Bidding begins to the dealer’s right'
                : bidding.history.map((record) =>
                    '${_playerNames[record.playerIndex]}: ${record.amount ?? "PASS"}').join('   •   '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 6,
            children: [
              for (var value = 4; value <= 8; value++)
                SizedBox(
                  width: 46,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: !_busy && value > highest ? () => _humanBid(value) : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF1B7A43),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white30,
                    ),
                    child: Text('$value', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  ),
                ),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _humanBid(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LorisApp.gold,
                    side: const BorderSide(color: LorisApp.gold),
                  ),
                  child: const Text('PASS', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrumpSelectionControls() {
    final bidder = _pendingTrumpBidder;
    if (bidder == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF4B1821),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LorisApp.gold),
      ),
      child: Column(
        children: [
          const Text('SELECT TRUMP CARD OR JOKER', style: TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 5),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 5,
            children: _pendingTrumpChoices.map((choice) {
              final isOwn = choice.key == bidder;
              final jokerUnavailable = choice.value.isLoris &&
                  !(_hands?[bidder].any((card) => card.isLoris) ?? false);
              final disabled = _busy || jokerUnavailable;
              return OutlinedButton(
                onPressed: disabled
                    ? null
                    : () => _applyTrump(bidder, choice.key, choice.value),
                style: OutlinedButton.styleFrom(
                  foregroundColor: jokerUnavailable ? Colors.white38 : Colors.white,
                  disabledForegroundColor: Colors.white30,
                  side: BorderSide(
                    color: jokerUnavailable
                        ? Colors.white24
                        : isOwn ? LorisApp.gold : Colors.white54,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCard(choice.value, compact: true),
                    const SizedBox(width: 5),
                    Text(
                      choice.value.isLoris
                          ? (jokerUnavailable ? 'JOKER • NOT IN HAND' : 'JOKER')
                          : isOwn
                              ? _cardName(choice.value)
                              : 'TEAMMATE ${choice.key + 1} • REVEAL',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<loris.Card> _sortedHand(List<loris.Card> cards) {
    const suitOrder = {
      loris.Suit.clubs: 0,
      loris.Suit.diamonds: 1,
      loris.Suit.hearts: 2,
      loris.Suit.spades: 3,
    };
    final sorted = List<loris.Card>.from(cards);
    sorted.sort((a, b) {
      if (a.isLoris != b.isLoris) return a.isLoris ? 1 : -1;
      if (a.isLoris) return 0;
      final suitCompare = suitOrder[a.suit]!.compareTo(suitOrder[b.suit]!);
      if (suitCompare != 0) return suitCompare;
      return b.rank!.compareTo(a.rank!);
    });
    return sorted;
  }

  Widget _buildHandStrip(List<loris.Card> cards) {
    if (_isDealingCards) {
      return const SizedBox.shrink();
    }
    final sortedCards = _sortedHand(cards);
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'YOUR HAND  •  REVIEW BEFORE BIDDING',
            style: TextStyle(color: LorisApp.gold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sortedCards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 3),
            itemBuilder: (context, index) => _buildCard(sortedCards[index]),
          ),
        ),
      ],
    );
  }

  Widget _teamTrickProgress(
    String label,
    int won,
    int target,
    Color accent,
  ) {
    final progress = target <= 0 ? 1.0 : (won / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1720),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              Text(
                '$won/$target',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white12,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMatchHeader() {
    final activeRound = _started ? _matchController.currentRound : null;
    final sixteenStatus = activeRound?.sixteenCallEngine?.status;
    final sixteenActive = sixteenStatus == SixteenCallStatus.inProgress ||
        sixteenStatus == SixteenCallStatus.succeeded ||
        sixteenStatus == SixteenCallStatus.failed;

    final teamATricks = activeRound == null
        ? 0
        : activeRound.biddingTeam == 0
            ? activeRound.biddingTeamTricks
            : activeRound.completedTricks - activeRound.biddingTeamTricks;
    final teamBTricks = activeRound == null
        ? 0
        : activeRound.biddingTeam == 1
            ? activeRound.biddingTeamTricks
            : activeRound.completedTricks - activeRound.biddingTeamTricks;

    final teamATarget = activeRound == null
        ? 0
        : sixteenActive
            ? (activeRound.biddingTeam == 0 ? 8 : 1)
            : activeRound.biddingTeam == 0
                ? activeRound.bidAmount
                : 9 - activeRound.bidAmount;
    final teamBTarget = activeRound == null
        ? 0
        : sixteenActive
            ? (activeRound.biddingTeam == 1 ? 8 : 1)
            : activeRound.biddingTeam == 1
                ? activeRound.bidAmount
                : 9 - activeRound.bidAmount;

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
            ],
          ),
          if (activeRound != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _teamTrickProgress(
                    'TEAM A  ${sixteenActive && activeRound.biddingTeam == 0 ? "CALL 16" : "TARGET"}',
                    teamATricks,
                    teamATarget,
                    const Color(0xFFFFD36A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _teamTrickProgress(
                    'TEAM B  ${sixteenActive && activeRound.biddingTeam == 1 ? "CALL 16" : "TARGET"}',
                    teamBTricks,
                    teamBTarget,
                    const Color(0xFFB8D9FF),
                  ),
                ),
              ],
            ),
          ],
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
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              if (_dealerIndex != null)
                Text(
                  '${_dealerDrawActive ? "STARTER" : "DEALER"}  ${_playerNames[_dealerIndex!]}',
                  style: const TextStyle(color: LorisApp.gold, fontSize: 10, fontWeight: FontWeight.w900),
                ),
            ],
          ),
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

  // ----------------------------------------------------------
  // INFO STRIPS
  // ----------------------------------------------------------

  // ----------------------------------------------------------
  // PLAYING TABLE
  // ----------------------------------------------------------

  void _showLastTrick() {
    if (_lastTrickPlays.isEmpty) return;
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF35101A),
      title: Text('LAST TRICK • ${_lastTrickWinner == null ? "UNKNOWN" : _playerNames[_lastTrickWinner!]} WON', style: const TextStyle(color: Color(0xFFFFE39A), fontSize: 14, fontWeight: FontWeight.w900)),
      content: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 10, children: [
        for (final play in _lastTrickPlays) Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_playerNames[play.playerIndex], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4), _buildCard(play.card, compact: true),
        ]),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE', style: TextStyle(color: Color(0xFFFFD978))))],
    ));
  }
  Widget _buildTableSurface(
    List<TrickPlay> plays,
    int? currentPlayer,
    List<int> handCounts, {
    List<loris.Card>? dealerDrawCards,
    int dealerDrawVisibleCount = 0,
    int dealerDrawStartPlayer = 0,
    bool dealerDrawActive = false,
  }) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableHeight = constraints.maxHeight;
        final seatWidth = widget.playerCount == 6 ? 88.0 : 96.0;

        return SizedBox(
          width: double.infinity,
          height: tableHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -.22),
                      radius: 1.18,
                      colors: [Color(0xFF8E2638), Color(0xFF641626), Color(0xFF310B17)],
                    ),
                  ),
                ),
              ),
                // Flat screen play surface; no 3D avatar renderer.
                if (dealerDrawCards != null && dealerDrawVisibleCount > 0)
                  Positioned(
                    top: tableHeight * .38, left: 0, right: 0,
                    child: IgnorePointer(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('DEALER DRAW', style: TextStyle(color: Color(0xFFFFE39A), fontSize: 9, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        _buildCard(dealerDrawCards[dealerDrawVisibleCount - 1], compact: true),
                      ]),
                    ),
                  ),
                if (_isDealingCards)
                  Positioned(top: tableHeight * .40, left: 0, right: 0, child: const IgnorePointer(child: Center(child: Text('DEALING CARDS…', style: TextStyle(color: Color(0xFFFFE39A), fontSize: 11, fontWeight: FontWeight.w900))))),
                if (plays.isNotEmpty)
                  for (var playIndex = 0; playIndex < plays.length; playIndex++)
                    Builder(builder: (context) {
                      final play = plays[playIndex];
                      if (_flightStarted &&
                          play.playerIndex == _flyingFromPlayer &&
                          play.card == _flyingCard) {
                        return const SizedBox.shrink();
                      }
                      final angles = widget.playerCount == 4 ? const [pi / 2, pi, -pi / 2, 0.0] : const [pi / 2, 2.59, 3.69, -pi / 2, -0.55, 0.55];
                      final angle = angles[play.playerIndex];
                      const cardWidth = 60.0, cardHeight = 86.0;
                      final radiusX = constraints.maxWidth * (widget.playerCount == 6 ? .205 : .22);
                      final radiusY = tableHeight * .17;
                      final cardX = constraints.maxWidth / 2 + cos(angle) * radiusX - cardWidth / 2;
                      final cardY = tableHeight * .51 + sin(angle) * radiusY - cardHeight / 2;
                      return Positioned(
                        left: cardX.clamp(0.0, constraints.maxWidth - cardWidth),
                        top: cardY.clamp(0.0, tableHeight - cardHeight),
                        child: IgnorePointer(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: const Color(0xEE17243B), borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFFFFD978), width: .7)), child: Text(_playerNames[play.playerIndex], style: const TextStyle(color: Color(0xFFFFE39A), fontSize: 8, fontWeight: FontWeight.w900))),
                          const SizedBox(height: 2),
                          Transform.rotate(angle: angle - pi / 2, child: _buildCard(play.card, compact: true, tableCard: true)),
                        ])),
                      );
                    }),
                if (_flightStarted && _flyingCard != null && _flyingFromPlayer != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('flight-$_flyingFromPlayer-$_flyingCard'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 560),
                        curve: Curves.easeOutCubic,
                        builder: (context, progress, child) {
                          final origin = seatAlignments[_flyingFromPlayer!];
                          final position = Alignment.lerp(origin, Alignment.center, progress)!;
                          final arc = sin(progress * pi) * 34;
                          return Align(
                            alignment: position,
                            child: Transform.translate(
                              offset: Offset(0, -arc),
                              child: child,
                            ),
                          );
                        },
                        child: _buildCard(_flyingCard!, compact: true),
                      ),
                    ),
                  ),
                // The entire screen is the play surface; no inset oval/table overlay.
                // Played cards remain in directional slots around the center so each
                // card is visibly associated with the seat that played it.
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
                          _AnimePortrait(seed: index, isFemale: _isFemalePlayer(_playerNames[index]), size: 42),
                          const SizedBox(height: 3),
                          Text(
                            _playerNames[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'TEAM ${index.isEven ? "A" : "B"}',
                            style: const TextStyle(color: Color(0xFFFFD978), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          if (_dealerIndex == index)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text('DEALER', style: TextStyle(color: LorisApp.gold, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          if (currentPlayer == index)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.circle, size: 6, color: Color(0xFFFFE7A0)),
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
                                          gradient: const LinearGradient(colors: [Color(0xFFB63A45), Color(0xFF5A1020)]),
                                          border: Border.all(color: const Color(0xFFFFD978), width: .5),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 3),
                                  Text('${handCounts[index]}', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          if (_collectingTrickWinner == index)
                            const Text('TRICK WON', style: TextStyle(color: Color(0xFFFFE7A0), fontSize: 9, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 7,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xCC260914),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66F5D78C), width: .7),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        child: Text(
                          _dealerDrawActive
                              ? 'DEALER DRAW'
                              : _isDealingCards
                                  ? 'DEALING  $_dealtCardCount/${widget.playerCount * 8}'
                                  : !_started
                                      ? _awaitingTrumpSelection
                                          ? 'CHOOSE TRUMP'
                                          : currentPlayer == null
                                              ? 'BIDDING'
                                              : 'BID • ${_playerNames[currentPlayer]}'
                                      : currentPlayer == null
                                          ? 'ROUND COMPLETE'
                                          : 'TURN • ${_playerNames[currentPlayer]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFFFE39A), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .35),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_lastTrickPlays.isNotEmpty)
                  Positioned(top: 34, right: 8, child: GestureDetector(
                    onTap: _showLastTrick,
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xEE17243B), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFD978), width: 1)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history, size: 13, color: Color(0xFFFFE39A)), SizedBox(width: 4), Text('LAST TRICK', style: TextStyle(color: Color(0xFFFFE39A), fontSize: 8, fontWeight: FontWeight.w900))])),
                  )),
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
                if (_showSixteenCallEffect)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            radius: 0.95,
                            colors: [Color(0xB8FFD778), Color(0x88A51E32), Color(0xAA260611)],
                            stops: [0, 0.48, 1],
                          ),
                        ),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.55, end: 1),
                            duration: const Duration(milliseconds: 720),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFE9A8), Color(0xFFE3A83E), Color(0xFF9B2432)],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFFFF4CF), width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Color(0xDDFFD36A), blurRadius: 34, spreadRadius: 8),
                                  BoxShadow(color: Colors.black87, blurRadius: 22, offset: Offset(0, 9)),
                                ],
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, color: Color(0xFF641323), size: 38),
                                  SizedBox(height: 3),
                                  Text('SIXTEEN CALL', style: TextStyle(
                                    color: Color(0xFF4B0C18), fontSize: 24,
                                    fontWeight: FontWeight.w900, letterSpacing: 2.4)),
                                  SizedBox(height: 5),
                                  Text('EVERY REMAINING TRICK', style: TextStyle(
                                    color: Color(0xFF5A1720), fontSize: 9,
                                    fontWeight: FontWeight.w900, letterSpacing: 1.7)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_trumpCard != null)
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xDD17243B),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: LorisApp.gold, width: 1),
                          ),
                          child: const Text(
                            'JOKER',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildCard(_trumpCard!, compact: true),
                      ],
                    ),
                  ),
              ],
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
    bool tableCard = false,
  }) {
    final isRed = _isRedSuit(card.suit);
    final ink = card.isLoris ? const Color(0xFF17243B) : isRed ? const Color(0xFFB51F32) : const Color(0xFF17202B);
    final width = tableCard ? 60.0 : compact ? 48.0 : 62.0;
    final height = tableCard ? 86.0 : compact ? 68.0 : 92.0;

    Widget corner({required bool upsideDown}) {
      return Transform.rotate(
        angle: upsideDown ? 3.1415926535 : 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.isLoris ? 'J' : card.displayName,
              style: TextStyle(color: ink, fontSize: tableCard ? 14 : compact ? 11 : 15, height: 1, fontWeight: FontWeight.w900)),
            Text(card.isLoris ? '★' : _suitSymbol(card.suit),
              style: TextStyle(color: ink, fontSize: tableCard ? 13 : compact ? 10 : 13, height: 1.05, fontWeight: FontWeight.bold)),
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
                      Icon(Icons.theater_comedy, color: ink, size: tableCard ? 25 : compact ? 19 : 25),
                      if (!compact) Text('JOKER', style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  )
                : card.rank != null && card.rank! >= 11 && card.rank! <= 13
                    ? _CourtCardArt(
                        rank: card.rank!,
                        ink: ink,
                        size: Size(tableCard ? 34 : compact ? 27 : 36, tableCard ? 46 : compact ? 36 : 49),
                      )
                    : Text(
                        _suitSymbol(card.suit),
                        style: TextStyle(
                          color: ink,
                          fontSize: tableCard ? 29 : compact ? 22 : 31,
                          fontWeight: FontWeight.w900,
                          shadows: const [Shadow(color: Color(0x22000000), blurRadius: 1, offset: Offset(1, 1))],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

}
class _AnimePortrait extends StatelessWidget {
  const _AnimePortrait({
    required this.seed,
    required this.isFemale,
    this.size = 36,
  });

  final int seed;
  final bool isFemale;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFFFD978), width: 1.5),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2)),
      ],
    ),
    child: ClipOval(
      child: CustomPaint(
        painter: _SuperheroPortraitPainter(seed, isFemale),
      ),
    ),
  );
}

class _SuperheroPortraitPainter extends CustomPainter {
  const _SuperheroPortraitPainter(this.seed, this.isFemale);

  final int seed;
  final bool isFemale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const backgrounds = [
      0xFF183D59, 0xFF612B43, 0xFF205342,
      0xFF40305F, 0xFF76502A, 0xFF24545E,
    ];
    const hairColors = [
      0xFF17151D, 0xFF45251D, 0xFF182432,
      0xFF71402A, 0xFF29202D, 0xFF4B3427,
    ];
    const suitColors = [
      0xFFB52E3D, 0xFF2476A4, 0xFFB47B25,
      0xFF6946A0, 0xFF267A68, 0xFFB64D27,
    ];
    const skinColors = [
      0xFFE7B995, 0xFFD49A75, 0xFFB97855,
      0xFF8E5944, 0xFFF0C7A2, 0xFFC88968,
    ];
    final background = Paint()..color = Color(backgrounds[seed % 6]);
    final hair = Paint()..color = Color(hairColors[seed % 6]);
    final suit = Paint()..color = Color(suitColors[seed % 6]);
    final skin = Paint()..color = Color(skinColors[seed % 6]);
    final dark = Paint()..color = const Color(0xFF171923);
    final white = Paint()..color = const Color(0xFFFFF8E9);
    final iris = Paint()..color = Color(suitColors[(seed + 2) % 6]);
    final gold = Paint()..color = const Color(0xFFFFD978);

    canvas.drawRect(Offset.zero & size, background);
    // Cape/shoulders and a distinct superhero suit.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .5, h * 1.02), width: w * .98, height: h * .62),
      suit,
    );
    final emblem = Path()
      ..moveTo(w * .5, h * .77)
      ..lineTo(w * .39, h * .88)
      ..lineTo(w * .5, h * .85)
      ..lineTo(w * .61, h * .88)
      ..close();
    canvas.drawPath(emblem, gold);

    // Hair silhouette differs by gender and player identity.
    if (isFemale) {
      canvas.drawOval(Rect.fromLTWH(w * .10, h * .08, w * .80, h * .88), hair);
      canvas.drawOval(Rect.fromLTWH(w * .23, h * .12, w * .54, h * .72), skin);
      canvas.drawOval(Rect.fromLTWH(w * .13, h * .20, w * .20, h * .64), hair);
      canvas.drawOval(Rect.fromLTWH(w * .67, h * .20, w * .20, h * .64), hair);
      final fringe = Path()
        ..moveTo(w * .19, h * .39)
        ..quadraticBezierTo(w * .25, h * .03, w * .56, h * .13)
        ..quadraticBezierTo(w * .78, h * .12, w * .82, h * .38)
        ..lineTo(w * .65, h * .31)
        ..lineTo(w * .51, h * .39)
        ..lineTo(w * .37, h * .30)
        ..close();
      canvas.drawPath(fringe, hair);
    } else {
      canvas.drawOval(Rect.fromLTWH(w * .19, h * .10, w * .62, h * .75), hair);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .25, h * .23, w * .50, h * .61),
          Radius.circular(w * .18),
        ),
        skin,
      );
      final fringe = Path()
        ..moveTo(w * .19, h * .39)
        ..quadraticBezierTo(w * .22, h * .06, w * .52, h * .10)
        ..quadraticBezierTo(w * .78, h * .07, w * .82, h * .35)
        ..lineTo(w * .67, h * .30)
        ..lineTo(w * .55, h * .38)
        ..lineTo(w * .43, h * .29)
        ..lineTo(w * .29, h * .39)
        ..close();
      canvas.drawPath(fringe, hair);
    }

    // Eye mask gives each portrait a clear superhero identity.
    final mask = Path()
      ..moveTo(w * .20, h * .43)
      ..quadraticBezierTo(w * .34, h * .35, w * .48, h * .43)
      ..quadraticBezierTo(w * .66, h * .35, w * .80, h * .43)
      ..lineTo(w * .73, h * .57)
      ..lineTo(w * .56, h * .52)
      ..lineTo(w * .50, h * .57)
      ..lineTo(w * .43, h * .52)
      ..lineTo(w * .27, h * .57)
      ..close();
    canvas.drawPath(mask, suit);
    for (final x in [w * .39, w * .61]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, h * .47), width: w * .17, height: h * .09),
        white,
      );
      canvas.drawCircle(Offset(x, h * .47), w * .035, iris);
      canvas.drawCircle(Offset(x, h * .47), w * .017, dark);
    }

    // Nose, mouth and gender-specific lower-face detail.
    canvas.drawLine(
      Offset(w * .5, h * .52),
      Offset(w * .48, h * .62),
      Paint()..color = const Color(0xFF9A604B)..strokeWidth = w * .025,
    );
    if (!isFemale) {
      canvas.drawArc(
        Rect.fromLTWH(w * .35, h * .60, w * .30, h * .20),
        0.15, 2.85, false,
        Paint()
          ..color = hair.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .055,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * .5, h * .68), width: w * .15, height: h * .045),
        Paint()..color = const Color(0xFF8E3E4C),
      );
    }
    // Distinct insignia and metallic trim.
    canvas.drawCircle(Offset(w * .5, h * .93), w * .035, gold);
  }

  @override
  bool shouldRepaint(covariant _SuperheroPortraitPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.isFemale != isFemale;
}


class _CourtCardArt extends StatelessWidget {
  const _CourtCardArt({
    required this.rank,
    required this.ink,
    required this.size,
  });

  final int rank;
  final Color ink;
  final Size size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: size,
    painter: _CourtCardPainter(rank, ink),
  );
}

class _CourtCardPainter extends CustomPainter {
  const _CourtCardPainter(this.rank, this.ink);

  final int rank;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()..color = const Color(0xFFC49A45);
    final dark = Paint()..color = const Color(0xFF29232A);
    final face = Paint()..color = const Color(0xFFE7B995);
    final cloth = Paint()..color = ink.withValues(alpha: .88);
    final white = Paint()..color = const Color(0xFFFFF8E9);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .08, h * .04, w * .84, h * .92),
        Radius.circular(w * .12),
      ),
      Paint()
        ..color = const Color(0xFFE6D7B7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Mirrored court-card shoulders and clothing.
    for (final flip in [false, true]) {
      canvas.save();
      if (flip) {
        canvas.translate(w, h);
        canvas.rotate(pi);
      }
      canvas.drawOval(Rect.fromLTWH(w * .13, h * .55, w * .74, h * .43), cloth);
      canvas.drawOval(Rect.fromLTWH(w * .29, h * .22, w * .42, h * .43), face);
      canvas.drawArc(
        Rect.fromLTWH(w * .25, h * .13, w * .50, h * .34),
        pi, pi, false,
        Paint()
          ..color = dark.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .10,
      );
      // Eyes, nose and beard/makeup details.
      for (final x in [w * .40, w * .60]) {
        canvas.drawCircle(Offset(x, h * .42), w * .035, dark);
        canvas.drawCircle(Offset(x - w * .01, h * .41), w * .012, white);
      }
      canvas.drawLine(
        Offset(w * .50, h * .44),
        Offset(w * .48, h * .53),
        Paint()..color = const Color(0xFF9B624D)..strokeWidth = w * .025,
      );
      if (rank == 13) {
        final beard = Path()
          ..moveTo(w * .31, h * .53)
          ..quadraticBezierTo(w * .50, h * .83, w * .69, h * .53)
          ..lineTo(w * .61, h * .62)
          ..lineTo(w * .50, h * .72)
          ..lineTo(w * .39, h * .62)
          ..close();
        canvas.drawPath(beard, dark);
      } else {
        canvas.drawArc(
          Rect.fromLTWH(w * .39, h * .53, w * .22, h * .12),
          0, pi, false,
          Paint()
            ..color = const Color(0xFF9B624D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .025,
        );
      }
      // Jacks wear a plume; queens and kings wear a crown.
      final crown = Path()
        ..moveTo(w * .28, h * .25)
        ..lineTo(w * .32, h * .10)
        ..lineTo(w * .43, h * .20)
        ..lineTo(w * .50, h * .07)
        ..lineTo(w * .57, h * .20)
        ..lineTo(w * .68, h * .10)
        ..lineTo(w * .72, h * .25)
        ..close();
      canvas.drawPath(crown, rank == 11 ? cloth : gold);
      canvas.restore();
    }

    // Rank-specific centre ornament.
    final emblem = rank == 11 ? 'J' : rank == 12 ? 'Q' : 'K';
    final painter = TextPainter(
      text: TextSpan(
        text: emblem,
        style: TextStyle(
          color: ink,
          fontSize: w * .20,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.white70, blurRadius: 1)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((w - painter.width) / 2, h * .76));
  }

  @override
  bool shouldRepaint(covariant _CourtCardPainter oldDelegate) =>
      oldDelegate.rank != rank || oldDelegate.ink != ink;
}
