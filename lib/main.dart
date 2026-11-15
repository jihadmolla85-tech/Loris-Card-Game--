import 'dart:math';
import 'game/widgets/dealer_reveal_dialog.dart';
import 'package:flutter/material.dart';

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

  bool _loading = false;
  bool _musicEnabled = true;
  bool _soundEnabled = true;

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
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Sound Effects'),
                    value: _soundEnabled,
                    activeThumbColor: LorisApp.gold,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                      updateDialog(() => _soundEnabled = value);
                    },
                  ),
                  const Text(
                    'Audio playback will be connected when the audio assets are added.',
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

class _GameScreenState extends State<GameScreen> {
  final GameSaveService _saveService = GameSaveService();
  final Random _random = Random();

  late final DealController _dealController;
  late final GameMatchController _matchController;

  List<List<loris.Card>>? _hands;

  BiddingRoundController? _biddingController;

  loris.Suit? _trumpSuit;

  bool _started = false;
  bool _finished = false;
  bool _busy = false;

  String _status = 'Press START MATCH to begin.';
  String? _error;

  int _trickNumber = 0;
  int? _lastTrickWinner;

  @override
  void initState() {
    super.initState();

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
      _bidAmount = snapshot.bidAmount;
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
      _error = null;
    });

    try {
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
);
      final dealtHands = _dealController.deal(
        deck: dealerSelection.shuffledDeck,
        playerCount: widget.playerCount,
        dealerIndex: dealerSelection.dealerIndex,
      );

      setState(() {
        _dealerIndex = dealerSelection.dealerIndex;
        _hands = dealtHands;
        _status = 'Cards dealt. Bidding begins.';
      });

      _startBidding();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
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
        _bidderIndex = null;
        _bidAmount = null;
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: LorisApp.blue,
          title: const Text('YOUR BID'),
          content: Text(
            'Current highest bid: ${bidding.highestBid ?? "-"}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, -1),
              child: const Text('PASS'),
            ),
            ...List.generate(5, (index) {
              final value = index + 4;

              return TextButton(
                onPressed: value > highestBid
                    ? () => Navigator.pop(dialogContext, value)
                    : null,
                child: Text('$value'),
              );
            }),
          ],
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

    _bidderIndex = bidder;
    _bidAmount = amount;

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

    final eligibleCards = <MapEntry<int, loris.Card>>[];

    for (var player = 0; player < hands.length; player++) {
      if (player % 2 != bidder % 2) continue;

      for (final card in hands[player]) {
        if (!card.isLoris && card.suit != null) {
          eligibleCards.add(MapEntry(player, card));
        }
      }
    }

    if (eligibleCards.isEmpty) {
      setState(() {
        _error = 'No eligible trump card found.';
      });
      return;
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
            height: 360,
            child: ListView.builder(
              itemCount: eligibleCards.length,
              itemBuilder: (context, index) {
                final item = eligibleCards[index];

                return ListTile(
                  title: Text(_cardName(item.value)),
                  subtitle: Text(
                    item.key == bidder
                        ? 'Your card'
                        : 'Teammate ${item.key + 1}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color: LorisApp.gold,
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext, item);
                  },
                );
              },
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

    for (var player = 0; player < hands.length; player++) {
      if (player % 2 != bidder % 2) continue;

      final counts = <loris.Suit, int>{
        for (final suit in loris.Suit.values) suit: 0,
      };

      for (final card in hands[player]) {
        if (!card.isLoris && card.suit != null) {
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
          _bidderIndex = null;
          _bidAmount = null;
          _started = false;

          _status = 'Redeal required. Same dealer remains.';
        });

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

  loris.Card _chooseAiCard(int playerIndex) {
    final engine = _matchController.currentRound.trickEngine;
    final hand = engine.hands[playerIndex];

    if (hand.isEmpty) {
      throw StateError('AI player has no cards.');
    }

    if (engine.plays.isNotEmpty) {
      final ledSuit = engine.ledSuit;

      final legalCards = hand.where((card) {
        return card.isLoris ||
            (card.suit != null && card.suit == ledSuit);
      }).toList();

      if (legalCards.isNotEmpty) {
        return legalCards.first;
      }
    }

    return hand.first;
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
      final winner = _matchController.completeTrick();

      _lastTrickWinner = winner;
      _trickNumber = round.completedTricks;

      setState(() {
        _status = 'Trick $_trickNumber won by Player ${winner + 1}.';
        _finished = round.isRoundEnded;
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
            : 'Player ${next + 1} to play.';
      });
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

        _bidderIndex = null;
        _bidAmount = null;
        _trumpSuit = null;

        _trickNumber = 0;
        _lastTrickWinner = null;

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
            const Icon(
              Icons.style,
              size: 76,
              color: LorisApp.gold,
            ),
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
    final round =
        _started ? _matchController.currentRound : null;

    final bidding = _biddingController;

    final currentPlayer = round?.nextPlayerIndex;

    final plays =
        round?.trickEngine.plays ?? const <TrickPlay>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _buildScoreBoard(),
          const SizedBox(height: 12),

          _infoStrip(
            'DEALER',
            _dealerIndex == null
                ? '-'
                : 'Player ${_dealerIndex! + 1}',
          ),

          _infoStrip(
            'TRUMP',
            _trumpSuit == null
                ? '-'
                : _suitName(_trumpSuit!),
          ),

          _infoStrip('STATUS', _status),

          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          const SizedBox(height: 12),

          if (!_started) ...[
            _buildBiddingTable(bidding),

            if (bidding != null &&
                bidding.isHumanTurn &&
                !bidding.isComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _humanBid,
                  child: const Text('MAKE YOUR BID'),
                ),
              ),
          ] else ...[
            _buildTableSurface(plays, currentPlayer),

            const SizedBox(height: 12),

            if (_humanCanCall16)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _call16,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LorisApp.gold,
                    foregroundColor: LorisApp.navy,
                  ),
                  child: const Text(
                    'CALL 16',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (_finished) ...[
              const SizedBox(height: 16),

              Text(
                _matchController.isMatchOver
                    ? 'MATCH FINISHED'
                    : 'ROUND FINISHED',
                style: const TextStyle(
                  color: LorisApp.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),

              if (_matchController.isMatchOver)
                Text(
                  'WINNER: ${_matchController.matchWinner.name.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _busy ? null : _nextRound,
                  child: const Text('NEXT ROUND'),
                ),
            ],
          ],

          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'YOUR HAND',
              style: TextStyle(
                color: LorisApp.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 9,
            children: hands[0].map((card) {
              final playable = _started &&
                  !_finished &&
                  !_busy &&
                  currentPlayer == 0;

              return GestureDetector(
                onTap: playable
                    ? () => _playHumanCard(card)
                    : null,
                child: _buildCard(
                  card,
                  enabled: playable,
                ),
              );
            }).toList(),
          ),

          if (_started &&
              !_finished &&
              currentPlayer != null &&
              currentPlayer != 0)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'AI is thinking...',
                style: TextStyle(color: Colors.white60),
              ),
            ),

          if (_started)
            TextButton.icon(
              onPressed: _saveGame,
              icon: const Icon(Icons.save),
              label: const Text('SAVE MATCH'),
            ),
        ],
      ),
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
          color: LorisApp.gold.withOpacity(.7),
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
        color: LorisApp.blue.withOpacity(.75),
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
                      child: Text(
                        isHuman ? 'YOU' : '${index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
              color: LorisApp.navy.withOpacity(.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'HIGHEST BID: ${bidding.highestBid ?? "-"}'
              '${bidding.highestBidder == null ? "" : "  •  PLAYER ${bidding.highestBidder! + 1}"}',
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
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LorisApp.tableGreen,
        borderRadius: BorderRadius.circular(110),
        border: Border.all(
          color: LorisApp.gold,
          width: 5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentPlayer == null
                ? 'ROUND COMPLETE'
                : 'TURN: PLAYER ${currentPlayer + 1}',
            style: const TextStyle(
              color: LorisApp.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 12,
            children: List.generate(widget.playerCount, (index) {
              final playerPlays = plays
                  .where((play) => play.playerIndex == index)
                  .toList();

              return SizedBox(
                width: 62,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      index == 0 ? 'YOU' : 'P${index + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (playerPlays.isEmpty)
                      Container(
                        width: 52,
                        height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white24,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      )
                    else
                      _buildCard(
                        playerPlays.last.card,
                        compact: true,
                      ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          if (_trumpSuit != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: LorisApp.navy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LorisApp.gold),
                ),
                child: Text(
                  'TRUMP ${_suitSymbol(_trumpSuit)}',
                  style: const TextStyle(
                    color: LorisApp.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
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

    final foreground = card.isLoris
        ? LorisApp.navy
        : isRed
            ? Colors.red
            : Colors.black87;

    final cardText = card.isLoris
        ? 'LORIS'
        : '${card.displayName}\n${_suitSymbol(card.suit)}';

    return Container(
      width: compact ? 52 : 62,
      height: compact ? 72 : 92,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: card.isLoris ? LorisApp.gold : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? LorisApp.gold : Colors.white70,
          width: enabled ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          cardText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: compact
                ? 13
                : card.isLoris
                    ? 11
                    : 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
