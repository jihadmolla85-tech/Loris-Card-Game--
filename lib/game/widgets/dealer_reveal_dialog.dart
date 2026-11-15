
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/loris_card.dart' as loris;

class DealerRevealDialog extends StatefulWidget {
  const DealerRevealDialog({
    super.key,
    required this.drawnCards,
    required this.playerCount,
    required this.dealerIndex,
  });

  final List<loris.Card> drawnCards;
  final int playerCount;
  final int dealerIndex;

  static Future<void> show(
    BuildContext context, {
    required List<loris.Card> drawnCards,
    required int playerCount,
    required int dealerIndex,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DealerRevealDialog(
        drawnCards: drawnCards,
        playerCount: playerCount,
        dealerIndex: dealerIndex,
      ),
    );
  }

  @override
  State<DealerRevealDialog> createState() =>
      _DealerRevealDialogState();
}

class _DealerRevealDialogState
    extends State<DealerRevealDialog> {
  int visibleCount = 0;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    revealCards();
  }

  Future<void> revealCards() async {
    for (var i = 0; i < widget.drawnCards.length; i++) {
      await Future.delayed(
        const Duration(milliseconds: 720),
      );

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

    if (mounted) {
      setState(() => finished = true);
    }
  }

String cardText(loris.Card card) {
    if (card.isLoris) return 'LORIS';

    final suit = switch (card.suit!) {
      loris.Suit.clubs => '♣',
      loris.Suit.diamonds => '♦',
      loris.Suit.hearts => '♥',
      loris.Suit.spades => '♠',
    };

    return '${card.displayName} $suit';
  }

  @override
  Widget build(BuildContext context) {
    final jackFound = visibleCount > 0 &&
        !widget.drawnCards[visibleCount - 1].isLoris &&
        widget.drawnCards[visibleCount - 1].rank == 11;

    return AlertDialog(
      backgroundColor: const Color(0xFF102B55),
      title: const Text(
        'DEALER SELECTION',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFD6B15E)),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cards revealed: $visibleCount / ${widget.drawnCards.length}',
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(visibleCount, (index) {
                final card = widget.drawnCards[index];
                final isJack =
                    !card.isLoris && card.rank == 11;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 62,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isJack
                        ? const Color(0xFFFFD76A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isJack
                          ? Colors.amber
                          : Colors.white70,
                      width: isJack ? 3 : 1,
                    ),
                    boxShadow: isJack
                        ? [
                            const BoxShadow(
                              color: Colors.amber,
                              blurRadius: 18,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    cardText(card),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isJack
                          ? Colors.black
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (jackFound)
              const Text(
                '🦉 JACK FOUND! DEALER SELECTED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFD76A),
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (!finished)
              const Text(
                'Revealing cards...',
                style: TextStyle(color: Colors.white70),
              )
            else
              const Text('Dealer selection complete.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: finished
              ? () => Navigator.pop(context)
              : null,
          child: const Text('CONTINUE'),
        ),
      ],
    );
  }
}
