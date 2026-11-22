
import '../models/loris_card.dart';
import 'card_dealer.dart';
import 'deck_shuffle_engine.dart';
import 'deck_validation_engine.dart';
import 'redeal_controller.dart';
import 'redeal_validation_engine.dart';

class DealController {
  DealController({
    required this.shuffleEngine,
    required this.redealController,
    required this.deckValidationEngine,
  });

  final DeckShuffleEngine shuffleEngine;
  final RedealController redealController;
  final DeckValidationEngine deckValidationEngine;

  List<Card>? _originalDeck;
  List<List<Card>>? _currentHands;

  int? _dealerIndex;
  int? _playerCount;

  List<List<Card>>? get currentHands => _currentHands;

  List<Card>? get originalDeck =>
      _originalDeck == null
          ? null
          : List<Card>.from(_originalDeck!);

  int? get dealerIndex => _dealerIndex;

  int? get playerCount => _playerCount;

  bool get shouldRedeal => redealController.shouldRedeal;

  List<List<Card>> deal({
    required List<Card> deck,
    required int playerCount,
    required int dealerIndex,
  }) {
    final validation = deckValidationEngine.validate(
      deck: deck,
      playerCount: playerCount,
    );

    if (!validation.isValid) {
      throw ArgumentError(
        'Invalid deck: ${validation.errors.join(', ')}',
      );
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
    final firstPlayerIndex = (dealer - 1 + players) % players;

    _currentHands = CardDealer.deal(
      deck: shuffledDeck,
      playerCount: players,
      firstPlayerIndex: firstPlayerIndex,
    );

    return _currentHands!;
  }

  void restoreDeal({
    required List<Card> originalDeck,
    required List<List<Card>> hands,
    required int dealerIndex,
    required int playerCount,
  }) {
    if (playerCount != 4 && playerCount != 6) {
      throw ArgumentError('Player count must be 4 or 6.');
    }

    if (dealerIndex < 0 || dealerIndex >= playerCount) {
      throw ArgumentError('Invalid dealer index.');
    }

    if (hands.length != playerCount ||
        hands.any((hand) => hand.length > 8)) {
      throw ArgumentError('Invalid saved hands.');
    }

    if (originalDeck.length != playerCount * 8) {
      throw ArgumentError('Invalid saved deck.');
    }

    _originalDeck = List<Card>.from(originalDeck);
    _currentHands = hands
        .map((hand) => List<Card>.from(hand))
        .toList();

    _dealerIndex = dealerIndex;
    _playerCount = playerCount;

    redealController.reset();
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

    redealController.reset();

    return _performDeal();
  }
}
