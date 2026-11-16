# Increment 20 integration — J-first dealer draw

## Integration decision

The Increment 20 standalone package used a one-pass, caller-configured reveal order. That behavior does not match the confirmed LORIS rule A, so its session/controller was **not copied** into this repository.

The existing production path is retained:

- `GameMatchController.selectInitialDealer`
- `InitialDealerSelector.select`
- `DealerRevealDialog`
- `_startMatch` in `lib/main.dart`

## Confirmed rule A

A random starting seat is selected. Cards are drawn one at a time from the shuffled draw pile. The seat advances clockwise/right after each non-Jack card, cycling through seats as often as necessary. The first player to draw a Jack becomes dealer immediately. The draw stops at that Jack, and the remaining deck is shuffled for dealing.

This is already the behavior of `InitialDealerSelector`; the integration therefore preserves the existing game controller and UI rather than replacing the app with Increment 20's separate sample `main.dart`.

## Regression coverage

`test/game/initial_dealer_selector_test.dart` now includes a case where the Jack appears only after more than four consecutive draws, proving that the selection continues through multiple seat rotations and assigns the Jack-drawing seat as dealer.

## Not claimed

This commit does not claim a completed APK build or Bluetooth multiplayer. The repository's push-triggered Flutter Quality Check workflow is responsible for analyze, tests, and a debug APK build.
