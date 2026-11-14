import '../models/loris_card.dart';
import 'card_dealer.dart';
import 'deck_shuffle_engine.dart';
import 'redeal_controller.dart';
import 'redeal_validation_engine.dart';

class DealController {
  DealController({
    required this.shuffleEngine,
    required this.redealController,
  });

  final DeckShuffleEngine shuffleEngine;
  final RedealController redealController;

  List<Card>? _originalDeck;
  List<List<Card>>? _currentHands;

  int? _dealerIndex;
  int? _playerCount;

  List<List<Card>>? get currentHands => _currentHands;

  int? get dealerIndex => _dealerIndex;

  bool get shouldRedeal => redealController.shouldRedeal;

  List<List<Card>> deal({
    required List<Card> deck,
    required int playerCount,
    required int dealerIndex,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (deck.length != playerCount * 8) {
      throw ArgumentError('Invalid deck size.');
    }

    if (dealerIndex < 0 || dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }

    _originalDeck = List<Card>.from(deck);
    _dealerIndex = dealerIndex;
    _playerCount = playerCount;

    redealController.reset();

    return _performDeal();
  }

  List<List<Card>> _performDeal() {
    final deck = _originalDeck!;
    final players = _playerCount!;
    final dealer = _dealerIndex!;

    final shuffledDeck = shuffleEngine.shuffle(deck);

    final firstPlayerIndex = (dealer + 1) % players;

    _currentHands = CardDealer.deal(
      deck: shuffledDeck,
      playerCount: players,
      firstPlayerIndex: firstPlayerIndex,
    );

    return _currentHands!;
  }

  RedealResult validateDeal({
    required bool everyonePassed,
    required bool bidderHasTrumpSuit,
  }) {
    final hands = _currentHands;
    final dealer = _dealerIndex;

    if (hands == null || dealer == null) {
      throw StateError('Deal has not started.');
    }

    return redealController.validate(
      hands: hands,
      dealerIndex: dealer,
      everyonePassed: everyonePassed,
      bidderHasTrumpSuit: bidderHasTrumpSuit,
    );
  }

  List<List<Card>> redeal() {
    if (!redealController.shouldRedeal) {
      throw StateError('Redeal is not required.');
    }

    return _performDeal();
  }
}
