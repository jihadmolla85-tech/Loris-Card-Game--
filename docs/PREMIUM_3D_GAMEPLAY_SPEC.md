# LORIS Premium Gameplay & Visual Specification

Status: development target for the draft release branch. This document is a specification, not evidence that the listed features already exist.

## 1. Screen composition (no gameplay scrolling)
- The complete live table must fit inside one screen on supported phone aspect ratios in portrait and landscape.
- Use a responsive, fixed game viewport with safe-area awareness. Never wrap the live table in a vertical or horizontal scroll view.
- The table is the dominant object: broad oval/rounded-rectangle premium felt table with raised rail, stitched/leather trim, subtle reflections, ambient occlusion and contact shadows.
- Keep seats, player names, team markers, bid/turn indicators and card-count visible simultaneously. Use existing 2D portraits; do not develop 3D human avatars or facial animation.
- Player hand stays at the bottom; card width/overlap scales to screen width and 8 cards remain selectable without scrolling.
- Scoreboard permanently shows Team A and Team B separately, plus round, trick and match state.

## 2. Visual scope and 3D assets
- Human avatar modeling, rigging, facial expression systems and facial animation are explicitly out of scope. Retain existing stylized 2D player portrait illustrations.
- Prioritize real runtime 3D table and card meshes/materials where feasible, plus dealer button, trump marker and other table props.
- Card model/art: clear printed faces and backs, refined edge/bevel and highlights; ensure faces remain readable and tappable.
- Table: felt surface, raised rim, material variation, stitching, tasteful details and real/baked shadows if performance allows.
- Provide a 2D fallback for devices that cannot sustain the table/card renderer; preserve all gameplay information and interactions.

## 3. Player seats & portrait treatment
- Seat positions are fixed around the table for 4 and 6 players. Human seat remains foreground/bottom; opponent seats remain readable at a glance.
- Existing 2D portraits may use restrained non-facial UI emphasis, such as seat glow, active-turn ring or bid badge. No face rigging, expression changes or character animation work.
- Highlight active player, dealer, bidder, trump chooser, trick winner and teammate with clear, restrained visual cues.
- During reveal actions, use a clear card/seat ownership cue; portraits are not required to animate.

## 4. Deal and shuffle choreography
- Show the deck being gathered, shuffled and squared before dealing. Shuffle animation should correspond to actual shuffled deck order when implemented.
- Deal in two passes: first pass gives each seat four cards in turn, second pass gives each seat four more cards in turn.
- Each card travels from the dealer/deck to its destination seat with visible origin, arc, rotation, perspective and contact landing.
- Use deliberate timing with small stagger between cards; avoid hands appearing without explanation.
- After the second pass, reveal the human player's eight-card hand clearly.

## 5. Bidding and announcements
- Announce every player's bid or pass separately, in turn order, with player name, portrait, a short cue and optional sound.
- Keep a visible bid history so users can see who bid what and who passed.
- The bot must choose a bid using its actual hand strength, trump distribution, LORIS value, teammate context, current high bid and risk; no random legal bid selection.
- Bot difficulty should support realistic, imperfect human-like play, with configurable skill and varied thinking delays. No hidden knowledge of opponents' cards.

## 6. Trump selection and teammate reveal
- Show who won the bidding, the bid amount and who selected trump.
- If the bidder selects a trump card from their own hand, show that card and the selection action.
- If a teammate must reveal an eligible card, show the card clearly with its owner and selection stage; no avatar animation is needed.
- Show the selected suit before the first trick using a dedicated trump reveal animation, sound cue and persistent trump marker.
- Make clear whether the trump choice was made from the bidder's own hand or a teammate's revealed card.

## 7. Trick play and card provenance
- Each card must visibly travel from its owner's seat to the table. The trajectory and seat origin must make the source player unmistakable.
- Keep each played card near its seat/position in the trick layout; never stack cards so tightly that ownership is unclear.
- Show the led suit as soon as the first card is played, with a persistent suit icon/label for the trick.
- Show player name/seat and card owner when a card lands. Preserve play order.
- LORIS card play has its own sound, restrained glow and brief emphasis.
- Trump card play has a separate cue from ordinary card placement.

## 8. Trick collection and scoring
- After the final player acts, pause briefly to show all cards and determine the winner.
- Highlight the winning card and winning seat. Then animate all cards in the trick one by one toward the winner's collection pile.
- The animation must preserve the identity of the winning player and show all cards being collected by that player.
- Update Team A/Team B trick counts and score only after the collection/award event completes.
- Keep current trick's led suit visible until the trick is fully collected.

## 9. 16-call, round and match outcomes
- 16-call: dedicated sound, visual banner and restrained table/card effect. The timing follows the agreed rule: immediately after the bidding team wins exactly its bid number of tricks, provided the opponents have won zero tricks in the round. The winner of that target-reaching trick may CALL 16 or PASS; PASS permanently closes the option for that round.
- Successful 16-call and failed 16-call have distinct outcome cues and score transitions.
- LORIS, trump, ordinary trick win, round win/loss and match win/loss should have clear, distinguishable visual/audio treatment.
- Round/match outcome overlays must show the winning team, score delta and updated match totals without hiding the table state.

## 10. Audio, ambience and accessibility
- Provide distinct sound assets for shuffle, deal, card landing, bid, pass, trump selection/reveal, trump play, LORIS play, 16-call, trick win/collection, round win/loss and match win/loss.
- Include optional low-volume ambience only with original or appropriately licensed recordings.
- Background music must be independently switchable and have its own volume control, separate from sound effects. Remember preferences where settings persistence supports it.
- Music should duck or pause under important announcements and effects; avoid competing sounds.
- Provide sound/music toggles and haptic cues where supported.
- Important information must remain visible as text/icons even when audio is muted.

## 11. Quality, performance and release gates
- 4-player and 6-player full-match tests must validate rules, turn order, trick collection, scoring, 16-call, dealer rotation and match completion.
- Integration tests must verify animations are driven by actual engine events and never change game state independently.
- Test on low-, mid- and high-tier Android devices; target stable 60 FPS where possible, with graceful fallback.
- No gameplay scrollbars or clipped seats/cards on supported screen sizes.
- Release candidate requires signed Android App Bundle/APK, install/launch smoke tests, audio checks, 4/6-player end-to-end QA and green CI.
- Online multiplayer, secure account sync, server-authoritative rewards/claims and payment integration remain deferred.

## 12. Current implementation truth
The Flutter project contains 2D table/card UI, stylized painted 2D portraits, audio hooks, card-flight animation and local 4/6-player game logic. These portraits are intentionally retained; human-avatar modeling and facial animation are excluded from the project's scope. Do not call existing portraits or 2D transforms true 3D. The draft branch is not release-ready until required gameplay coverage, table/card rendering polish, end-to-end tests and release gates are implemented and verified.
