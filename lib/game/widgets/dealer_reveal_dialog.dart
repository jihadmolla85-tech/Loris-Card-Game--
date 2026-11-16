import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../models/loris_card.dart' as loris;

class DealerRevealDialog extends StatefulWidget {
  const DealerRevealDialog({
    super.key,
    required this.drawnCards,
    required this.playerCount,
    required this.dealerIndex,
    required this.firstPlayerIndex,
    required this.playerNames,
    required this.playerAvatars,
  });

  final List<loris.Card> drawnCards;
  final int playerCount;
  final int dealerIndex;
  final int firstPlayerIndex;
  final List<String> playerNames;
  final List<String> playerAvatars;

  static Future<void> show(
    BuildContext context, {
    required List<loris.Card> drawnCards,
    required int playerCount,
    required int dealerIndex,
    required int firstPlayerIndex,
    required List<String> playerNames,
    required List<String> playerAvatars,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DealerRevealDialog(
        drawnCards: drawnCards,
        playerCount: playerCount,
        dealerIndex: dealerIndex,
        firstPlayerIndex: firstPlayerIndex,
        playerNames: playerNames,
        playerAvatars: playerAvatars,
      ),
    );
  }

  @override
  State<DealerRevealDialog> createState() => _DealerRevealDialogState();
}

class _DealerRevealDialogState extends State<DealerRevealDialog> {
  int visibleCount = 0;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    revealCards();
  }

  Future<void> revealCards() async {
    for (var i = 0; i < widget.drawnCards.length; i++) {
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      setState(() => visibleCount = i + 1);
      await SystemSound.play(SystemSoundType.click);

      final card = widget.drawnCards[i];
      if (!card.isLoris && card.rank == 11) {
        await HapticFeedback.heavyImpact();
        if (!mounted) return;
        setState(() => finished = true);
        return;
      }
    }
    if (mounted) setState(() => finished = true);
  }

  List<loris.Card> _cardsForPlayer(int playerIndex) {
    final cards = <loris.Card>[];
    for (var i = 0; i < visibleCount; i++) {
      final recipient = (widget.firstPlayerIndex + i) % widget.playerCount;
      if (recipient == playerIndex) cards.add(widget.drawnCards[i]);
    }
    return cards;
  }

  String _cardText(loris.Card card) {
    if (card.isLoris) return 'LORIS';
    final suit = switch (card.suit!) {
      loris.Suit.clubs => '♣',
      loris.Suit.diamonds => '♦',
      loris.Suit.hearts => '♥',
      loris.Suit.spades => '♠',
    };
    return '${card.displayName}\n$suit';
  }

  Color _cardInk(loris.Card card) {
    return card.suit == loris.Suit.hearts || card.suit == loris.Suit.diamonds
        ? Colors.red.shade700
        : Colors.black87;
  }

  Widget _revealedCard(loris.Card card) {
    final isJack = !card.isLoris && card.rank == 11;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 38,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isJack ? const Color(0xFFFFD76A) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isJack ? Colors.amber : Colors.white70,
          width: isJack ? 2.5 : 1,
        ),
        boxShadow: isJack
            ? [const BoxShadow(color: Colors.amber, blurRadius: 13)]
            : const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
      ),
      child: Text(
        _cardText(card),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isJack ? Colors.black : _cardInk(card),
          fontWeight: FontWeight.w900,
          fontSize: 12,
          height: 1.05,
        ),
      ),
    );
  }

  Widget _playerRow(int playerIndex) {
    final cards = _cardsForPlayer(playerIndex);
    final isDealer = finished && playerIndex == widget.dealerIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isDealer ? const Color(0xFF59451B) : const Color(0xFF0A2041),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDealer ? const Color(0xFFFFD76A) : Colors.white12,
          width: isDealer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 91,
            child: Row(
              children: [
                Text(widget.playerAvatars[playerIndex], style: const TextStyle(fontSize: 25)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.playerNames[playerIndex],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDealer ? const Color(0xFFFFD76A) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SizedBox(
              height: 56,
              child: cards.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Waiting for card...', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (_, index) => _revealedCard(cards[index]),
                    ),
            ),
          ),
          if (isDealer) ...[
            const SizedBox(width: 5),
            const Icon(Icons.workspace_premium, color: Color(0xFFFFD76A), size: 19),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jackFound = visibleCount > 0 &&
        !widget.drawnCards[visibleCount - 1].isLoris &&
        widget.drawnCards[visibleCount - 1].rank == 11;

    return AlertDialog(
      backgroundColor: const Color(0xFF102B55),
      title: const Text(
        'JACK • DEALER DRAW',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFD6B15E), fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 370,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ONE CARD AT A TIME  •  $visibleCount REVEALED',
              style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(widget.playerCount, _playerRow),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (jackFound)
              Text(
                '${widget.playerAvatars[widget.dealerIndex]}  JACK FOUND!\n${widget.playerNames[widget.dealerIndex].toUpperCase()} IS THE DEALER',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD76A),
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
              )
            else if (!finished)
              const Text(
                'The dealer is giving the next card...',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              )
            else
              const Text('Dealer selection complete.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: finished ? () => Navigator.pop(context) : null,
          child: const Text('CONTINUE'),
        ),
      ],
    );
  }
}
