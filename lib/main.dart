
r'''import 'dart:math';

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
import 'game/engine/game_state_snapshot.dart';
import 'game/engine/bidding_round_controller.dart';
import 'game/engine/trump_selection_engine.dart';
import 'game/engine/sixteen_call_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LorisApp());
}

class LorisApp extends StatelessWidget {
  const LorisApp({super.key});

  static const navy = Color(0xFF07152E);
  static const blue = Color(0xFF102B55);
  static const gold = Color(0xFFD6B15E);

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

class LorisHomeScreen extends StatefulWidget {
  const LorisHomeScreen({super.key});

  @override
  State<LorisHomeScreen> createState() => _LorisHomeScreenState();
}

class _LorisHomeScreenState extends State<LorisHomeScreen> {
  final GameSaveService _save = GameSaveService();
  bool _busy = false;
  bool _music = true;
  bool _sounds = true;

  Future<void> _newGame() async {
    final count = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LorisApp.blue,
        title: const Text('SELECT PLAYERS'),
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
    if (!mounted || count == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(playerCount: count)),
    );
  }

  Future<void> _resume() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final snapshot = await _save.load();
      if (!mounted) return;
      if (snapshot == null || snapshot.playerCount == null) {
        _message('No saved match found.');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              playerCount: snapshot.playerCount!,
              savedSnapshot: snapshot,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _message('Could not resume match: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  void _settings() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          backgroundColor: LorisApp.blue,
          title: const Text('SETTINGS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Background Music'),
                value: _music,
                activeThumbColor: LorisApp.gold,
                onChanged: (v) {
                  setState(() => _music = v);
                  update(() => _music = v);
                },
              ),
              SwitchListTile(
                title: const Text('Sound Effects'),
                value: _sounds,
                activeThumbColor: LorisApp.gold,
                onChanged: (v) {
                  setState(() => _sounds = v);
                  update(() => _sounds = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
            colors: [LorisApp.blue, LorisApp.navy, Color(0xFF030A16)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium,
                      size: 78, color: LorisApp.gold),
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
                  const SizedBox(height: 38),
                  Container(width: 190, height: 2, color: LorisApp.gold),
                  const SizedBox(height: 38),
                  _menuButton('NEW GAME', Icons.play_arrow, _newGame, true),
                  const SizedBox(height: 16),
                  _menuButton(
                    _busy ? 'LOADING...' : 'RESUME GAME',
                    Icons.restore,
                    _busy ? null : _resume,
                  ),
                  const SizedBox(height: 16),
                  _menuButton('SETTINGS', Icons.settings, _settings),
                  const SizedBox(height: 42),
                  const Text(
                    'STRATEGY • TEAMWORK • VICTORY',
                    style: TextStyle(color: Colors.white38, letterSpacing: 2),
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
    VoidCallback? action, [
    bool primary = false,
  ]) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: primary
          ? ElevatedButton.icon(
              onPressed: action,
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: LorisApp.gold,
                foregroundColor: LorisApp.navy,
              ),
            )
          : OutlinedButton.icon(
              onPressed: action,
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
  final GameSaveService _save = GameSaveService();

  late final GameMatchController _match;
  late final DealController _deal;
  final Random _random = Random();

  List<List<loris.Card>>? _hands;
  BiddingRoundController? _auction;
  int? _dealer;
  int? _bidder;
  int? _bid;
  loris.Suit? _trump;

  bool _busy = false;
  bool _started = false;
  bool _finished = false;
  String _status = 'Press START MATCH to deal the cards.';
  String? _error;
  int? _lastWinner;
  int _trickNumber = 0;

  @override
  void initState() {
    super.initState();
    _deal = DealController(
      shuffleEngine: DeckShuffleEngine(random: _random),
      redealController: RedealController(
        validationEngine: RedealValidationEngine(),
      ),
      deckValidationEngine: DeckValidationEngine(),
    );
    _match = GameMatchController(
      initialDealerIndex: widget.savedSnapshot?.dealerIndex ?? 0,
      matchScoreEngine: MatchScoreEngine(),
      bidScoringEngine: BidScoringEngine(),
      dealController: _deal,
    );
    if (widget.savedSnapshot != null) {
      _restore(widget.savedSnapshot!);
    }
  }

  void _restore(GameStateSnapshot snapshot) {
    try {
      _match.restoreSnapshot(snapshot);
      if (_match.hasStarted) {
        _hands = _match.currentRound.trickEngine.hands;
        _dealer = snapshot.dealerIndex;
        _bid = snapshot.bidAmount;
        _bidder = snapshot.biddingTeam == null
            ? null
            : _findBidderForTeam(snapshot.biddingTeam!);
        _trump = snapshot.trumpSuit;
        _started = true;
        _finished = _match.currentRound.isRoundEnded;
        _status = 'Saved match restored.';
        _trickNumber = snapshot.completedTricks;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_finished) _runAiTurns();
        });
      } else {
        _status = 'Saved deal restored. Bidding must be restarted.';
      }
      setState(() {});
    } catch (e) {
      _error = 'Resume failed: $e';
      setState(() {});
    }
  }

  int _findBidderForTeam(int team) => team;

  Future<void> _startMatch() async {
    if (_busy || _hands != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final deck = loris.LorisDeck.create(
        widget.playerCount == 4
            ? loris.PlayerCount.four
            : loris.PlayerCount.six,
        random: _random,
      );
      final selection = _match.selectInitialDealer(
        deck: deck,
        playerCount: widget.playerCount,
        random: _random,
      );
      final dealt = _deal.deal(
        deck: selection.shuffledDeck,
        playerCount: widget.playerCount,
        dealerIndex: selection.dealerIndex,
      );
      setState(() {
        _dealer = selection.dealerIndex;
        _hands = dealt;
        _status = 'Cards dealt. Bidding begins.';
      });
      _startAuction();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startAuction() {
    final currentHands = _hands;
    final dealer = _dealer;
    if (currentHands == null || dealer == null) return;
    try {
      final auction = BiddingRoundController(
        hands: currentHands,
        dealerIndex: dealer,
        humanPlayerIndex: 0,
      );
      setState(() {
        _auction = auction;
        _started = false;
        _bidder = null;
        _bid = null;
        _trump = null;
        _status = auction.isComplete
            ? 'Bidding complete.'
            : auction.isHumanTurn
                ? 'Your turn to bid.'
                : 'AI players are bidding.';
      });
      if (auction.isComplete) _finishAuction();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _humanBid() async {
    final auction = _auction;
    if (auction == null || !auction.isHumanTurn || _busy) return;
    final highest = auction.highestBid ?? 3;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LorisApp.blue,
        title: const Text('YOUR BID'),
        content: Text('Current highest bid: ${auction.highestBid ?? "-"}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, -1),
            child: const Text('PASS'),
          ),
          ...List.generate(5, (i) {
            final value = i + 4;
            return TextButton(
              onPressed: value > highest
                  ? () => Navigator.pop(ctx, value)
                  : null,
              child: Text('$value'),
            );
          }),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _busy = true);
    try {
      auction.submitHumanBid(result == -1 ? null : result);
      setState(() {
        _status = auction.isComplete
            ? 'Bidding complete.'
            : auction.isHumanTurn
                ? 'Your turn to bid.'
                : 'AI players are bidding.';
      });
      if (auction.isComplete) await _finishAuction();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishAuction() async {
    final auction = _auction;
    if (auction == null || !auction.isComplete) return;
    if (auction.everyonePassed) {
      await _validateDeal(
        everyonePassed: true,
        bidderHasTrump: true,
      );
      return;
    }
    final bidder = auction.highestBidder;
    final amount = auction.highestBid;
    if (bidder == null || amount == null) {
      setState(() => _error = 'Invalid auction result.');
      return;
    }
    _bidder = bidder;
    _bid = amount;
    if (bidder == 0) {
      await _chooseHumanTrump(bidder);
    } else {
      await _chooseAiTrump(bidder);
    }
  }

  Future<void> _chooseHumanTrump(int bidder) async {
    final currentHands = _hands;
    if (currentHands == null) return;
    final eligible = <MapEntry<int, loris.Card>>[];
    for (var p = 0; p < currentHands.length; p++) {
      if (p % 2 != bidder % 2) continue;
      for (final card in currentHands[p]) {
        if (!card.isLoris && card.suit != null) {
          eligible.add(MapEntry(p, card));
        }
      }
    }
    final selected = await showDialog<MapEntry<int, loris.Card>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: LorisApp.blue,
        title: const Text('SELECT TRUMP'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: ListView.builder(
            itemCount: eligible.length,
            itemBuilder: (ctx, i) {
              final item = eligible[i];
              return ListTile(
                title: Text(item.value.displayName),
                subtitle: Text(item.key == bidder
                    ? 'Your card'
                    : 'Teammate ${item.key + 1}'),
                onTap: () => Navigator.pop(ctx, item),
              );
            },
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    await _applyTrump(
      bidder,
      selected.key,
      selected.value,
    );
  }

  Future<void> _chooseAiTrump(int bidder) async {
    final currentHands = _hands;
    if (currentHands == null) return;
    loris.Suit? bestSuit;
    var bestCount = -1;
    var owner = bidder;
    for (var p = 0; p < currentHands.length; p++) {
      if (p % 2 != bidder % 2) continue;
      final counts = <loris.Suit, int>{
        for (final suit in loris.Suit.values) suit: 0,
      };
      for (final card in currentHands[p]) {
        if (!card.isLoris && card.suit != null) {
          counts[card.suit!] = counts[card.suit!]! + 1;
        }
      }
      for (final entry in counts.entries) {
        if (entry.value > bestCount) {
          bestCount = entry.value;
          bestSuit = entry.key;
          owner = p;
        }
      }
    }
    if (bestSuit == null || bestCount <= 0) {
      setState(() => _error = 'AI could not select trump.');
      return;
    }
    final card = currentHands[owner].firstWhere(
      (c) => !c.isLoris && c.suit == bestSuit,
    );
    await _applyTrump(bidder, owner, card);
  }

  Future<void> _applyTrump(
    int bidder,
    int owner,
    loris.Card card,
  ) async {
    final currentHands = _hands;
    final auction = _auction;
    if (currentHands == null || auction == null) return;
    try {
      final result = TrumpSelectionEngine.select(
        hands: currentHands,
        bidderIndex: bidder,
        highestBidderIndex: auction.highestBidder!,
        cardOwnerIndex: owner,
        selectedCard: card,
      );
      _trump = result.trumpSuit;
      await _validateDeal(
        everyonePassed: false,
        bidderHasTrump: result.bidderHasTrumpSuit,
        trump: result.trumpSuit,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _validateDeal({
    required bool everyonePassed,
    required bool bidderHasTrump,
    loris.Suit? trump,
  }) async {
    final auction = _auction;
    if (auction == null) return;
    try {
      final newHands = _match.validateAndRedeal(
        everyonePassed: everyonePassed,
        bidderHasTrumpSuit: bidderHasTrump,
      );
      if (_deal.shouldRedeal) {
        setState(() {
          _hands = newHands;
          _status = 'Redeal required. Dealer remains Player ${_dealer! + 1}.';
          _trump = null;
          _bidder = null;
          _bid = null;
        });
        _startAuction();
        return;
      }
      if (trump == null || auction.highestBid == null ||
          auction.highestBidder == null) {
        setState(() => _error = 'Trump or bid result is missing.');
        return;
      }
      _match.startRoundWithCurrentDeal(
        trumpSuit: trump,
        biddingTeam: auction.highestBidder! % 2,
        bidAmount: auction.highestBid!,
      );
      setState(() {
        _started = true;
        _status = 'Round started. ${_suitName(trump)} is trump.';
      });
      await _runAiTurns();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  loris.Card _chooseAiCard(int player) {
    final engine = _match.currentRound.trickEngine;
    final hand = engine.hands[player];
    if (engine.plays.isNotEmpty) {
      final led = engine.ledSuit;
      final following = hand.where((c) =>
          c.isLoris || (c.suit != null && c.suit == led)).toList();
      if (following.isNotEmpty) return following.first;
    }
    return hand.first;
  }

  Future<void> _playHumanCard(loris.Card card) async {
    if (!_started || _finished || _busy) return;
    final round = _match.currentRound;
    if (round.nextPlayerIndex != 0) return;
    setState(() => _busy = true);
    try {
      _match.playCard(0, card);
      await _afterCardPlayed();
      await _runAiTurns();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runAiTurns() async {
    if (!_started || _finished || !mounted) return;
    var safety = 0;
    while (mounted &&
        !_match.currentRound.isRoundEnded &&
        _match.currentRound.nextPlayerIndex != 0 &&
        safety < widget.playerCount) {
      safety++;
      final player = _match.currentRound.nextPlayerIndex!;
      final card = _chooseAiCard(player);
      _match.playCard(player, card);
      await _afterCardPlayed();
      if (!mounted || _finished) return;
    }
  }

  Future<void> _afterCardPlayed() async {
    final round = _match.currentRound;
    if (round.trickEngine.isComplete) {
      final winner = _match.completeTrick();
      _lastWinner = winner;
      _trickNumber = round.completedTricks;
      setState(() {
        _status = 'Trick $_trickNumber won by Player ${winner + 1}.';
        _finished = round.isRoundEnded;
      });
      if (_finished) {
        _status = 'Round complete. Team A: ${_match.matchScoreEngine.teamAScore}  '
            'Team B: ${_match.matchScoreEngine.teamBScore}';
      }
    } else {
      setState(() {
        _status = 'Player ${round.nextPlayerIndex! + 1} to play.';
      });
    }
  }

  Future<void> _call16() async {
    if (!_started || _finished || _busy) return;
    final engine = _match.currentRound.sixteenCallEngine;
    if (engine == null || !engine.canCall ||
        engine.lastTrickWinnerIndex != 0) return;
    try {
      _match.call16(callerPlayerIndex: 0);
      setState(() => _status = '16 CALL! Your team must win every remaining trick.');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _saveGame() async {
    try {
      await _match.saveGame(_save);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match saved successfully.')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
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

  @override
  Widget build(BuildContext context) {
    final currentHands = _hands;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LORIS MATCH'),
        backgroundColor: LorisApp.blue,
        actions: [
          if (_started)
            IconButton(
              tooltip: 'Save match',
              onPressed: _saveGame,
              icon: const Icon(Icons.save, color: LorisApp.gold),
            ),
        ],
      ),
      body: SafeArea(
        child: currentHands == null
            ? _startPanel()
            : _gamePanel(currentHands),
      ),
    );
  }

  Widget _startPanel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 72, color: LorisApp.gold),
            const SizedBox(height: 20),
            Text('${widget.playerCount} PLAYERS',
                style: const TextStyle(
                    color: LorisApp.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.playerCount == 4
                ? '1 Human + 3 AI • Teams A-B-A-B'
                : '1 Human + 5 AI • Teams A-B-A-B-A-B'),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _busy ? null : _startMatch,
              icon: const Icon(Icons.play_arrow),
              label: Text(_busy ? 'STARTING...' : 'START MATCH'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gamePanel(List<List<loris.Card>> hands) {
    final round = _started ? _match.currentRound : null;
    final auction = _auction;
    final currentPlayer = round?.nextPlayerIndex;
    final plays = round?.trickEngine.plays ?? const [];
    final canCall = round?.sixteenCallEngine?.canCall == true &&
        round?.sixteenCallEngine?.lastTrickWinnerIndex == 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _scoreBoard(),
          const SizedBox(height: 12),
          _infoStrip('DEALER', _dealer == null ? '-' : 'Player ${_dealer! + 1}'),
          _infoStrip('TRUMP', _trump == null ? '-' : _suitName(_trump!)),
          _infoStrip('STATUS', _status),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          const SizedBox(height: 12),
          if (!_started) ...[
            _biddingTable(auction),
            if (auction?.isHumanTurn == true && !auction!.isComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _humanBid,
                  child: const Text('MAKE YOUR BID'),
                ),
              ),
          ] else ...[
            _tableSurface(plays, currentPlayer),
            const SizedBox(height: 12),
            if (canCall)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _call16,
                  child: const Text('CALL 16'),
                ),
              ),
            if (_finished)
              const Text('ROUND FINISHED',
                  style: TextStyle(
                      color: LorisApp.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
          ],
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('YOUR HAND',
                style: TextStyle(
                    color: LorisApp.gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
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
                onTap: playable ? () => _playHumanCard(card) : null,
                child: _cardWidget(card, enabled: playable),
              );
            }).toList(),
          ),
          if (_started && !_finished && currentPlayer != 0)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('AI is thinking...',
                  style: TextStyle(color: Colors.white60)),
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

  Widget _scoreBoard() {
    final score = _match.matchScoreEngine;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: LorisApp.blue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LorisApp.gold.withOpacity(.65)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _score('TEAM A', score.teamAScore),
          Container(width: 1, height: 38, color: LorisApp.gold),
          _score('TEAM B', score.teamBScore),
        ],
      ),
    );
  }

  Widget _score(String label, int value) => Column(
        children: [
          Text(label, style: const TextStyle(color: LorisApp.gold)),
          Text('$value',
              style: const TextStyle(
                  fontSize: 25, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _infoStrip(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LorisApp.blue.withOpacity(.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LorisApp.gold)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _biddingTable(BiddingRoundController? auction) {
    if (auction == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B442F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LorisApp.gold, width: 2),
      ),
      child: Column(
        children: [
          const Text('BIDDING TABLE',
              style: TextStyle(
                  color: LorisApp.gold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.playerCount, (i) {
              final record = auction.history
                  .where((r) => r.playerIndex == i)
                  .toList();
              final bidText = record.isEmpty
                  ? '—'
                  : record.last.amount == null
                      ? 'PASS'
                      : '${record.last.amount}';
              return Column(
                children: [
                  CircleAvatar(
                    backgroundColor: i == 0 ? LorisApp.gold : LorisApp.navy,
                    foregroundColor: i == 0 ? LorisApp.navy : Colors.white,
                    child: Text(i == 0 ? 'YOU' : '${i + 1}'),
                  ),
                  const SizedBox(height: 6),
                  Text(bidText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Highest: ${auction.highestBid ?? "-"}'
            '${auction.highestBidder == null ? "" : " • Player ${auction.highestBidder! + 1}"}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _tableSurface(List plays, int? currentPlayer) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF075239),
        borderRadius: BorderRadius.circular(110),
        border: Border.all(color: LorisApp.gold, width: 5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6)),
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
                color: LorisApp.gold, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: List.generate(widget.playerCount, (i) {
              final play = plays.where((p) => p.playerIndex == i).toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(i == 0 ? 'YOU' : 'P${i + 1}',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  play.isEmpty
                      ? Container(
                          width: 52,
                          height: 72,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        )
                      : _cardWidget(play.last.card, compact: true),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _cardWidget(loris.Card card,
      {bool enabled = false, bool compact = false}) {
    final suit = card.suit;
    final red = suit == loris.Suit.hearts || suit == loris.Suit.diamonds;
    final symbol = switch (suit) {
      loris.Suit.clubs => '♣',
      loris.Suit.diamonds => '♦',
      loris.Suit.hearts => '♥',
      loris.Suit.spades => '♠',
      null => '',
    };
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
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(2, 3)),
        ],
      ),
      child: Center(
        child: Text(
          card.isLoris ? 'LORIS' : '${card.displayName}\n$symbol',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: card.isLoris
                ? LorisApp.navy
                : red
                    ? Colors.red
                    : Colors.black87,
            fontSize: compact ? 13 : (card.isLoris ? 11 : 21),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
'''
path = Path("/mnt/data/main.dart")
path.write_text(source, encoding="utf-8")
print(f"Created complete replacement: {path.name} ({len(source.splitlines())} lines, {path.stat().st_size:,} bytes)")
