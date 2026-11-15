
Widget _buildDealtGame(List<List<loris.Card>> hands) {
  final bidding = _biddingController;

  final seatAlignments = hands.length == 4
      ? const [
          Alignment(0, 0.94),
          Alignment(-0.94, 0),
          Alignment(0, -0.94),
          Alignment(0.94, 0),
        ]
      : const [
          Alignment(0, 0.94),
          Alignment(-0.82, 0.58),
          Alignment(-0.82, -0.58),
          Alignment(0, -0.94),
          Alignment(0.82, -0.58),
          Alignment(0.82, 0.58),
        ];

  Widget playerSeat(int index) {
    final isHuman = index == 0;
    final isDealer = index == _dealerIndex;
    final isHighestBidder = bidding?.highestBidder == index;
    final team = index.isEven ? 'TEAM A' : 'TEAM B';

    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isHighestBidder
            ? const Color(0xFF8A681D)
            : const Color(0xFF102D43),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighestBidder
              ? LorisApp.gold
              : Colors.white24,
          width: isHighestBidder ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHuman ? Icons.person : Icons.smart_toy,
                size: 14,
                color: LorisApp.gold,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isHuman ? 'YOU' : 'PLAYER ${index + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$team • ${hands[index].length} cards',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
          if (isDealer || isHighestBidder) ...[
            const SizedBox(height: 4),
            Text(
              isHighestBidder ? 'HIGHEST BID' : 'DEALER',
              style: const TextStyle(
                color: LorisApp.gold,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium,
              color: LorisApp.gold,
              size: 25,
            ),
            const SizedBox(width: 8),
            const Text(
              'LORIS MATCH',
              style: TextStyle(
                color: LorisApp.gold,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'DEALER: PLAYER ${_dealerIndex! + 1}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _statusMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // TABLE AREA
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 390,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Green table
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF075A3B),
                        borderRadius: BorderRadius.circular(150),
                        border: Border.all(
                          color: LorisApp.gold,
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Inner table border
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(140),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  // Player seats around the table
                  ...List.generate(hands.length, (index) {
                    return Align(
                      alignment: seatAlignments[index],
                      child: playerSeat(index),
                    );
                  }),

                  // Central bidding panel
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: constraints.maxWidth * 0.55,
                      constraints: const BoxConstraints(
                        maxWidth: 220,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF092D27),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: LorisApp.gold,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'BIDDING TABLE',
                            style: TextStyle(
                              color: LorisApp.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Divider(
                            color: Colors.white30,
                            height: 15,
                          ),
                          const Text(
                            'HIGHEST BID',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${bidding?.highestBid ?? "-"}',
                            style: const TextStyle(
                              color: LorisApp.gold,
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bidding?.highestBidder == null
                                ? 'No bidder yet'
                                : 'Player ${bidding!.highestBidder! + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          const Divider(
                            color: Colors.white30,
                            height: 15,
                          ),
                          const Text(
                            'BID HISTORY',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (bidding == null ||
                              bidding.history.isEmpty)
                            const Text(
                              'Waiting for bids...',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            )
                          else
                            ...bidding.history
                                .take(4)
                                .map(
                                  (record) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'P${record.playerIndex + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _bidActionText(record),
                                          style: const TextStyle(
                                            color: LorisApp.gold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  // Trump corner
                  Positioned(
                    top: 17,
                    right: 13,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102D43),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: LorisApp.gold,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TRUMP',
                            style: TextStyle(
                              color: LorisApp.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedTrump == null
                                ? '?'
                                : _suitName(_selectedTrump!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        if (bidding != null &&
            bidding.isHumanTurn &&
            !bidding.isComplete &&
            !_roundStarted)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _processing ? null : _showBidDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: LorisApp.gold,
                foregroundColor: LorisApp.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'MAKE YOUR BID',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

        if (_roundStarted) ...[
          Text(
            'WINNING BID: $_winningBid',
            style: const TextStyle(
              color: LorisApp.gold,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Bidding completed',
            style: TextStyle(color: Colors.white70),
          ),
        ],

        const SizedBox(height: 18),
        const Divider(color: LorisApp.gold),
        const Text(
          'YOUR HAND',
          style: TextStyle(
            color: LorisApp.gold,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
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
