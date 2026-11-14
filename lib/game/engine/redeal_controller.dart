
import '../models/loris_card.dart';
import 'redeal_validation_engine.dart';

class RedealController {
  RedealController({
    required this.validationEngine,
  });

  final RedealValidationEngine validationEngine;

  RedealResult? _lastResult;

  RedealResult? get lastResult => _lastResult;

  bool get shouldRedeal =>
      _lastResult?.shouldRedeal ?? false;

  int? get dealerIndex =>
      _lastResult?.sameDealerIndex;

  RedealResult validate({
    required List<List<Card>> hands,
    required int dealerIndex,
    required bool everyonePassed,
    required bool bidderHasTrumpSuit,
  }) {
    final result = validationEngine.evaluate(
      hands: hands,
      dealerIndex: dealerIndex,
      everyonePassed: everyonePassed,
      bidderHasTrumpSuit: bidderHasTrumpSuit,
    );

    _lastResult = result;

    return result;
  }

  void restoreResult({
    required bool shouldRedeal,
    required List<String> reasons,
    required int dealerIndex,
  }) {
    final restoredReasons = RedealReason.values
        .where((reason) => reasons.contains(reason.name))
        .toList();

    _lastResult = RedealResult(
      shouldRedeal: shouldRedeal,
      reasons: restoredReasons,
      sameDealerIndex: dealerIndex,
    );
  }

  void reset() {
    _lastResult = null;
  }
}
