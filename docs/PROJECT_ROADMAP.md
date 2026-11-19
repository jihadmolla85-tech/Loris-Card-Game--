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

- [ ] Latest Flutter analyze, all tests, and Android APK build must pass on the current PR head.
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
