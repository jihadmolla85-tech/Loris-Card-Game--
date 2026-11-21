# LORIS Project Roadmap

This file is the continuity checklist for future development. Update it whenever a requirement changes; do not remove an item just because another area is being edited.

## Core rules and game engine

- [x] Four-player deck: ranks 7 through Ace, 32 cards total, with the designated Spades slot replaced by LORIS.
- [x] Six-player deck: ranks 3 through Ace, 48 cards total, with the designated Spades slot replaced by LORIS.
- [x] Four or six players, two alternating teams, eight cards per player.
- [x] Deal cards in four-card batches.
- [x] Bidding begins to the dealer's right; players may bid or pass.
- [x] Winning bidder can select a suit from their own hand.
- [x] Winning bidder may select TEAMMATE'S HAND; one eligible ordinary card is selected randomly and only its suit becomes trump. Never reveal the card face or rank.
- [x] Joker/LORIS trump option is available only when the bidder personally holds LORIS.
- [x] LORIS card is labelled L and has custom Joker artwork.
- [x] CALL 16 eligibility, one-time pass/call choice, and success/failure scoring are covered by engine tests.
- [x] Trick completion has a UI re-entry guard; AI loop stops when a trick is already complete.\n- [x] AI turn progression allows the same player to lead consecutive tricks after winning; stall checks verify committed cards instead of banning repeated player indexes.
- [x] Detach per-card autosave from the AI turn loop so slow storage cannot hold the next AI action.\n- [x] Add spoken Bangla bid announcements with English fallback.\n- [x] Add persistent trump label and suit name in the compact header.\n- [x] Slow the four-card dealing packet animation to 500 ms per player.\n- [ ] Verify the trick-completion fix in a full 4-player and 6-player match on a physical Android device.
- [ ] Continue regression testing for AI turn stalls, saved-match resume, redeals, and all CALL 16 edge cases.

## Privacy and trump selection

- [x] Trump selection does not expose teammate card faces or ranks.
- [x] Trump indicator shows only the trump suit symbol or LORIS Joker art.
- [x] Human bidder's own eight-card hand remains visible while choosing.
- [ ] Confirm the random teammate card is selected from the correct partner seat in both 4-player and 6-player modes.
- [x] Add engine tests for private random teammate-card selection in four- and six-player modes.\n- [ ] Add automated UI tests for trump-choice privacy and teammate random-card selection.

## Player portraits and branding

- [x] Added a portrait atlas built from the user's supplied chibi superhero reference sheet.
- [x] Six distinct portraits are integrated into player seats with circular gold frames.
- [x] Existing LORIS logo assets are retained for the home screen and app branding.
- [ ] Integrate the remaining supplied portrait choices as a larger selectable/random portrait pool.
- [x] Correct the supplied 6×4 portrait atlas crop to use dynamic cell dimensions.\n- [ ] Review portrait crop quality and visibility on small Android screens.
- [ ] Keep Android, iOS, web and desktop app icons/splash assets consistent with the approved LORIS logo.

## Visual/gameplay experience

- [x] Burgundy play surface and 3D table scene are present.
- [x] Player seats show names, team identity, and turn/dealer/winner emphasis.
- [x] Card play, dealing, trick and round feedback systems exist in the project.
- [x] Add visible center-to-seat Jack reveal and dealer-to-player four-card packet animations.\n- [x] Move the AI bidding THINKING label from the scoreboard to the active player's portrait.\n- [x] Enlarge and label the in-game trump indicator.\n- [ ] Continue improving card clarity, spacing, directional card orientation, and last-trick visibility.
- [ ] Review the quality and consistency of card, trump, LORIS, trick-win, round-win and match-win effects.
- [ ] Check responsive layout with the bottom hand, dialogs, and ad-safe area on different phone sizes.
- [ ] Verify sound effects and haptics never block the AI/game progression.

## Quality gates

- [x] Flutter analyze, all tests, Android APK build, and artifact upload passed on commit `cfb0c77f` (CI Run #581).
- [ ] Test both 4-player and 6-player gameplay end-to-end.
- [ ] Confirm save/resume does not duplicate or skip a trick.
- [ ] Test on a physical Android device; CI alone is not device QA.
- [ ] Do not merge PR #3 or change main until the user explicitly approves.

## Working rules

1. Work only on `feature/three-d-far-view` unless the user asks otherwise.
2. Fetch the latest PR head and each file's current SHA before editing.
3. Preserve existing features and tests when changing a screen or engine.
4. Update this checklist as work is completed; distinguish code implementation from verified device behaviour.
5. Never report a test, build, or device check as successful unless the corresponding result was actually observed.

### 2026-11-19 — AI turn continuation fix
- Increased the AI turn safety limit to allow a legal sequence to cross a completed-trick boundary when an AI wins and leads the next trick before the human's next turn. The old one-table-rotation limit could pause valid play early.
- CI verification pending for this commit; physical-device gameplay verification remains pending.

### 2026-11-19 — Dealer rotation scoring correction
- Corrected the dealer rule to use the dealer team's cumulative match total: the dealer changes only when that team's total score is +1 or higher. A round's individual win/loss does not override this total-score threshold.
- Added a regression test confirming the dealer rotates when the cumulative total remains +2 even though the team loses 4 points in the current round.
- CI Run #580 passed on the latest branch head.


### 2026-11-19 — Right-to-left play and trump-selection correction
- Bidding, dealing, and trick progression move from the dealer's right-hand seat toward the left.
- AI trump selection evaluates ordinary suit lengths instead of automatically selecting LORIS when held.
- LORIS is a special card, not an ordinary Spades card: whenever it is played, it wins the trick. If no LORIS is played, the highest card of the selected trump suit wins when trump is present; otherwise the highest card of the led suit wins.
- LORIS/Joker trump mode has no ordinary trump suit; when no LORIS card appears, the highest card of the led suit wins.
- CI and physical-device verification pending.


### 2026-11-19 — LORIS card winner rule clarification
- Corrected the trick winner rule: if the special LORIS card appears in a trick, its player wins that trick.
- If no LORIS card appears, the highest card of the selected trump suit wins when trump is present; otherwise the highest card of the led suit wins.
- Updated the AI's simulated trick-winner calculation to match the engine rule.
- Added regression coverage for LORIS beating a higher ordinary trump card.
- Removed unused winner-helper methods that caused Flutter Analyze to fail.
- Automated CI and physical-device verification pending.


### 2026-11-19 — CI regression repair for right-to-left gameplay
- The first CI run confirmed Flutter Analyze passed but tests failed because several fixtures still expected clockwise turn order and some trick fixtures played cards that were not in the named player's hand.
- Corrected trick-test hands to match the actual right-to-left seat sequence and fixed a malformed six-player dealer-rotation test.
- Updated bidding, round, and match controller test expectations for dealer-right first action, right-to-left progression, and dealer rotation.
- Re-running CI on the latest branch head; Android build and device verification remain unconfirmed.


### 2026-11-21 — Repair outdated trick and bidding test fixtures
- Corrected trick-engine test cards so every played card is actually in that player's hand; the previous fixtures attempted to play absent ranks and failed at the legal-card guard.
- Corrected the animated bidding test's expected next seat to match dealer-right, right-to-left progression.
- No game rules or runtime engine behavior changed in this repair.
- CI verification pending.


### 2026-11-21 — LORIS card play effect polish
- Added an elastic entrance, layered purple gradient, gold rim, and stronger glow to the LORIS play announcement.
- Existing card-flight timing, sound, haptic timeout protection, and gameplay state transitions remain unchanged.
- CI Run #580 passed on the latest branch head; effect timing and readability still need physical-device review.


### 2026-11-21 — CI Run #578 passed
- Flutter Analyze, the full existing test suite, Android APK build, and artifact upload all completed successfully for commit `0770f0b0b7a19d931d3eadb45ce151ae2a20f42b`.
- The subsequent LORIS play-effect polish commit `214cda73` is not covered by Run #578 and requires a fresh CI result.


### 2026-11-21 — Correct LORIS rulebook explanation and CI Run #580
- Updated the in-game Playing Tricks instructions to match the engine: LORIS wins any trick in which it is played; otherwise the selected trump suit wins when present, or the led suit wins when there is no ordinary trump.
- Confirmed Flutter Analyze, all existing tests, Android APK build, and APK artifact upload passed on commit `a72609620da0da7acee50161cfc0a4870bced405` (CI Run #580).
- Physical-device checks for four-player and six-player matches, save/resume, animation readability, and responsive layouts remain outstanding.


### 2026-11-21 — Six-player CALL 16 regression coverage
- Added six-player engine tests that exercise all three teammate seats during a successful CALL 16 and confirm an opponent trick breaks eligibility.
- CI Run #581 passed for the previous commit; this new test-only change requires its own CI run.
- Physical-device verification remains outstanding.
