
import 'dart:math';

import 'package:flutter/material.dart';

import 'game/models/loris_card.dart' as loris;
import 'game/models/loris_deck.dart' as loris;

import 'game/ai/ai_bidding_strategy.dart';

import 'game/engine/game_match_controller.dart';
import 'game/engine/match_score_engine.dart';
import 'game/engine/bid_scoring_engine.dart';
import 'game/engine/deal_controller.dart';
import 'game/engine/deck_shuffle_engine.dart';
import 'game/engine/deck_validation_engine.dart';
import 'game/engine/redeal_controller.dart';
import 'game/engine/redeal_validation_engine.dart';
import 'game/engine/game_save_service.dart';
import 'game/engine/bidding_round_controller.dart';
import 'game/engine/trump_selection_engine.dart';

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
  bool _roundStarted = false;
  bool _processing = false;

  String? _error;
  String? _statusMessage;

  int? _dealerIndex;
  List<List<loris.Card>>? _hands;

  GameMatchController? _matchController;
  DealController? _dealController;
  BiddingRoundController? _biddingController;

  loris.Suit? _selectedTrump;
  int? _winningBid;
  int? _winningBidder;

  void _startGame() {
    if (_starting || _hands != null) return;

    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final random = Random();

      final playerType = widget.playerCount == 4
          ? loris.PlayerCount.four
          : loris.PlayerCount.six;

      final deck = loris.LorisDeck.create(
        playerType,
        random: random,
      );

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

      final selection = matchController.selectInitialDealer(
        deck: deck,
        playerCount: widget.playerCount,
        random: random,
      );

      final hands = dealController.deal(
        deck: selection.shuffledDeck,
        playerCount: widget.playerCount,
        dealerIndex: selection.dealerIndex,
      );

      _matchController = matchController;
      _dealController = dealController;

      setState(() {
        _dealerIndex = selection.dealerIndex;
        _hands = hands;
        _starting = false;
        _statusMessage = 'Cards dealt. Bidding is ready.';
      });

      _startAuction();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _starting = false;
      });
    }
  }

  void _startAuction() {
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
        _roundStarted = false;
        _selectedTrump = null;
        _winningBid = null;
        _winningBidder = null;
        _statusMessage = controller.isComplete
            ? 'Bidding completed.'
            : controller.isHumanTurn
                ? 'Your turn to bid.'
                : 'AI players are bidding.';
      });

      if (controller.isComplete) {
        _finishBidding();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _showBidDialog() async {
    final controller = _biddingController;

    if (controller == null ||
        !controller.isHumanTurn ||
        _processing) {
      return;
    }

    final highest = controller.highestBid ?? 3;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LorisApp.blue,
        title: const Text(
          'YOUR BID',
          style: TextStyle(color: LorisApp.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current highest bid: ${controller.highestBid ?? "-"}'),
            const SizedBox(height: 14),
            const Text('Choose your bid or pass.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, -1),
            child: const Text('PASS'),
          ),
          ...List.generate(5, (index) {
            final amount = index + 4;

            return if (amount > highest)
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  amount,
                ),
                child: Text('$amount'),
              );
          }),
        ],
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _processing = true);

    try {
      controller.submitHumanBid(
        result == -1 ? null : result,
      );

      setState(() {
        _statusMessage = controller.isComplete
            ? 'Bidding completed.'
            : controller.isHumanTurn
                ? 'Your turn to bid.'
                : 'AI players are bidding.';
      });

      if (controller.isComplete) {
        await _finishBidding();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _finishBidding() async {
    final controller = _biddingController;
    final match = _matchController;

    if (controller == null || match == null) return;
    if (!controller.isComplete) return;

    if (controller.everyonePassed) {
      await _redealAndRestart(
        everyonePassed: true,
        bidderHasTrumpSuit: true,
      );
      return;
    }

    final bidder = controller.highestBidder;
    final bid = controller.highestBid;

    if (bidder == null || bid == null) {
      setState(() {
        _error = 'Bidding result is invalid.';
      });
      return;
    }

    setState(() {
      _winningBidder = bidder;
      _winningBid = bid;
      _statusMessage = 'Player ${bidder + 1} won the bidding.';
    });

    if (bidder == 0) {
      await _showTrumpSelectionDialog(bidder);
    } else {
      await _selectAiTrump(bidder);
    }
  }

  Future<void> _showTrumpSelectionDialog(int bidder) async {
    final hands = _hands;

    if (hands == null) return;

    final teammate = (bidder + 2) % hands.length;

    final options = <MapEntry<int, loris.Card>>[];

    for (final card in hands[bidder]) {
      if (!card.isLoris && card.suit != null) {
        options.add(MapEntry(bidder, card));
      }
    }

    for (final card in hands[teammate]) {
      if (!card.isLoris && card.suit != null) {
        options.add(MapEntry(teammate, card));
      }
    }

    final selected = await showDialog<MapEntry<int, loris.Card>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LorisApp.blue,
        title: const Text(
          'SELECT TRUMP',
          style: TextStyle(color: LorisApp.gold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final card = option.value;

              return ListTile(
                leading: const Icon(
                  Icons.style,
                  color: LorisApp.gold,
                ),
                title: Text(card.displayName),
                subtitle: Text(
                  option.key == bidder
                      ? 'Your card'
                      : 'Teammate card - Player ${option.key + 1}',
                ),
                onTap: () => Navigator.pop(
                  dialogContext,
                  option,
                ),
              );
            },
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;

    await _resolveTrumpSelection(
      bidderIndex: bidder,
      cardOwnerIndex: selected.key,
      selectedCard: selected.value,
    );
  }

  Future<void> _selectAiTrump(int bidder) async {
    final hands = _hands;

    if (hands == null) return;

    final hand = hands[bidder];

    final suitCounts = <loris.Suit, int>{
      for (final suit in loris.Suit.values) suit: 0,
    };

    for (final card in hand) {
      if (!card.isLoris && card.suit != null) {
        suitCounts[card.suit!] =
            (suitCounts[card.suit!] ?? 0) + 1;
      }
    }

    final preferredSuit = suitCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    ).key;

    final selectedCard = hand.firstWhere(
      (card) =>
          !card.isLoris && card.suit == preferredSuit,
    );

    await _resolveTrumpSelection(
      bidderIndex: bidder,
      cardOwnerIndex: bidder,
      selectedCard: selectedCard,
    );
  }

  Future<void> _resolveTrumpSelection({
    required int bidderIndex,
    required int cardOwnerIndex,
    required loris.Card selectedCard,
  }) async {
    final hands = _hands;
    final match = _matchController;

    if (hands == null || match == null) return;

    try {
      final result = TrumpSelectionEngine.select(
        hands: hands,
        bidderIndex: bidderIndex,
        highestBidderIndex: _winningBidder!,
        cardOwnerIndex: cardOwnerIndex,
        selectedCard: selectedCard,
      );

      setState(() {
        _selectedTrump = result.trumpSuit;
        _statusMessage =
            'Trump selected: ${_suitName(result.trumpSuit)}';
      });

      await _redealAndRestart(
        everyonePassed: false,
        bidderHasTrumpSuit: result.bidderHasTrumpSuit,
        trumpSuit: result.trumpSuit,
      );
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _redealAndRestart({
    required bool everyonePassed,
    required bool bidderHasTrumpSuit,
    loris.Suit? trumpSuit,
  }) async {
    final match = _matchController;
    final controller = _biddingController;
    final dealer = _dealerIndex;

    if (match == null || controller == null || dealer == null) {
      return;
    }

    try {
      final newHands = match.validateAndRedeal(
        everyonePassed: everyonePassed,
        bidderHasTrumpSuit: bidderHasTrumpSuit,
      );

      final dealController = _dealController;

      if (dealController == null) return;

      if (dealController.shouldRedeal) {
        setState(() {
          _hands = newHands;
          _selectedTrump = null;
          _winningBid = null;
          _winningBidder = null;
          _statusMessage =
              'Redeal required. Same dealer: Player ${dealer + 1}.';
        });

        _startAuction();
        return;
      }

      if (trumpSuit == null ||
          controller.highestBid == null ||
          controller.highestBidder == null) {
        setState(() {
          _error = 'Unable to complete bidding.';
        });
        return;
      }

      match.startRoundWithCurrentDeal(
        trumpSuit: trumpSuit,
        biddingTeam: controller.highestBidder! % 2,
        bidAmount: controller.highestBid!,
      );

      setState(() {
        _roundStarted = true;
        _statusMessage =
            'Round initialized. Trump: ${_suitName(trumpSuit)}';
      });
    } catch (error) {
      setState(() => _error = error.toString());
    }
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

  String _bidActionText(BidRecord record) {
    if (record.amount == null) return 'PASS';
    return 'BID ${record.amount}';
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
            Text(
              widget.playerCount == 4
                  ? 'Teams: A - B - A - B'
                  : 'Teams: A - B - A - B - A - B',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
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
    final bidding = _biddingController;

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
            'LORIS MATCH',
            style: TextStyle(
              color: LorisApp.gold,
              fontSize: 22,
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
          Text(
            _statusMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 20),
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
                  isHuman ? 'You' : 'AI Player $index',
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
          const SizedBox(height: 20),
          const Divider(color: LorisApp.gold),
          const Text(
            'BIDDING',
            style: TextStyle(
              color: LorisApp.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Highest bid: ${bidding?.highestBid ?? "-"}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          if (bidding?.highestBidder != null)
            Text(
              'Highest bidder: Player ${bidding!.highestBidder! + 1}',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 12),
          if (bidding != null)
            ...bidding.history.map(
              (record) => Card(
                color: LorisApp.blue,
                child: ListTile(
                  dense: true,
                  title: Text(
                    'Player ${record.playerIndex + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    _bidActionText(record),
                    style: const TextStyle(
                      color: LorisApp.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (bidding != null &&
              bidding.isHumanTurn &&
              !bidding.isComplete &&
              !_roundStarted)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : _showBidDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LorisApp.gold,
                  foregroundColor: LorisApp.navy,
                ),
                child: const Text(
                  'MAKE YOUR BID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_roundStarted) ...[
            const SizedBox(height: 14),
            Text(
              'Winning bid: $_winningBid',
              style: const TextStyle(
                color: LorisApp.gold,
                fontSize: 18,
              ),
            ),
            Text(
              'Trump: ${_selectedTrump == null ? "-" : _suitName(_selectedTrump!)}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bidding and trump selection completed. The playable table is the next integration task.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: LorisApp.gold),
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
