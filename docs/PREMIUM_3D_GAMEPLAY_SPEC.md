# LORIS Premium 3D Gameplay Specification

Status: implementation target for the draft release branch. This document is a specification, not evidence that the listed features already exist.

## 1. Screen composition (no gameplay scrolling)
- The complete live table must fit inside one screen on supported phone aspect ratios in portrait and landscape.
- Use a responsive, fixed game viewport with safe-area awareness. Never wrap the live table in a vertical or horizontal scroll view.
- The table is the dominant object: broad oval/rounded-rectangle premium felt table with a raised rail, stitched/leather trim, subtle reflections, ambient occlusion and contact shadows.
- Opponent avatars are smaller and visually farther from the table centre. Keep every seat, name, team marker, bid/turn indicator and card-count visible simultaneously.
- Player hand stays at the bottom; card width/overlap scales to screen width and 8 cards remain selectable without scrolling.
- Scoreboard permanently shows Team A and Team B separately, plus round, trick and match state.

## 2. 3D art direction and assets
- Use real authored 3D assets (GLB/glTF or equivalent): human avatars, table, card meshes, dealer button, trump marker and premium UI props.
- No emoji avatars, flat portrait illustrations, painted pseudo-3D or static screenshots as substitutes for the final 3D models.
- Avatars should be low-poly/high-quality game-ready models with PBR skin, hair, clothing and facial rigs; use LODs and texture atlases for mobile performance.
- Card model: physically thick rounded card edge, paper texture, printed face/back materials, subtle bevel and physically plausible highlights.
- Table: large oval felt surface, raised rim, material variation, stitching, engraved details and baked/real-time shadows.
- Provide a 2D fallback only for devices that cannot sustain the 3D renderer; it must preserve all gameplay information and interactions.

## 3. Player seats and expression system
- Seat positions are fixed around the table for 4 and 6 players. Human seat remains foreground/bottom; opponents appear smaller and farther away.
- Every avatar must have a facial rig or blend-shape expression set: neutral, focused, thinking, confident, surprised, happy, disappointed and tense.
- Expression changes are event-driven and occasionally idle-randomized with cooldowns; never flicker or change so often that they distract.
- Highlight the active player, dealer, bidder, trump chooser, trick winner and teammate with distinct restrained visual cues.
- During reveal actions, the relevant avatar receives the card near their seat with a clear ownership cue.

## 4. Deal and shuffle choreography
- Show the deck being gathered, riffle/overhand shuffled and squared before dealing. The shuffle animation must correspond to the actual shuffled deck order.
- Deal in two passes: first pass gives each seat four cards in turn, second pass gives each seat four more cards in turn.
- Each card travels from the dealer/deck to its destination seat with visible origin, arc, rotation, perspective and contact landing.
- Use deliberate slow motion with small stagger between cards; do not teleport hands into existence.
- After the second pass, reveal the human player's eight-card hand clearly at the bottom.

## 5. Bidding and announcements
- Announce every player's bid or pass separately, in turn order, with player name, avatar reaction and a short voice/sound cue.
- Keep a visible bid history so users can see who bid what and who passed.
- The bot must choose a bid using its actual hand strength, trump distribution, LORIS value, teammate context, current high bid and risk; no random legal bid selection.
- Bot difficulty should support realistic, imperfect human-like play, with configurable skill and varied thinking delays. No hidden knowledge of opponents' cards.

## 6. Trump selection and teammate reveal
- Show who won the bidding, the bid amount and who selected trump.
- If the bidder selects a trump card from their own hand, show that card and the selection action.
- If a teammate must reveal an eligible card, animate the reveal one player at a time: move the chosen card toward that teammate's avatar, show the face beside the avatar, then animate it to the table/selection stage.
- Show the selected suit before the first trick using a dedicated trump reveal animation, sound cue and persistent trump marker.
- Make clear whether the trump choice was made from the bidder's own hand or a teammate's revealed card.

## 7. Trick play and card provenance
- Each card must visibly travel from its owner's seat to the table. The trajectory and seat origin must make the source player unmistakable.
- Keep each played card near its seat/position in the trick layout; never stack cards so tightly that ownership is unclear.
- Show the led suit as soon as the first card is played, with a persistent suit icon/label for the trick.
- Show player name/seat and card owner when a card lands. Preserve play order.
- LORIS card play has its own sound, glow, particle trail and brief slow-motion emphasis.
- Trump card play has a separate cue from ordinary card placement.

## 8. Trick collection and scoring
- After the final player acts, pause briefly to show all cards and determine the winner.
- Highlight the winning card and winning avatar. Then animate all cards in the trick one by one toward the winner's seat/collection pile in slow motion.
- The animation must preserve the identity of the winning player and show all cards being collected by that player.
- Update Team A/Team B trick counts and score only after the collection/award event completes.
- Keep current trick's led suit visible until the trick is fully collected.

## 9. 16-call, round and match outcomes
- 16-call: dedicated sound, visual banner, avatar reaction and gold/energy effect. The timing must follow the agreed rule: after the bidding team has already won its bid number of tricks, it must win the next trick before the call is available.
- Successful 16-call and failed 16-call have distinct outcome animations and score transitions.
- LORIS, trump, ordinary trick win, round win, round loss, match win and match loss each need distinct sound and visual treatment.
- Round/match outcome overlays must show the winning team, score delta and updated match totals without hiding the table state.

## 10. Audio and accessibility
- Provide separate authored sound assets for shuffle, each card deal, card landing, bid, pass, trump selection/reveal, trump play, LORIS play, 16-call, trick win/collection, round win/loss and match win/loss.
- Mix and duck sounds to avoid overlapping announcements. Provide sound/music toggles and haptic cues.
- Important information must remain visible as text/icons even when audio is muted.

## 11. Quality, performance and release gates
- 4-player and 6-player full-match tests must validate rules, turn order, trick collection, scoring, 16-call, dealer rotation and match completion.
- Integration tests must verify every animation is driven by the actual engine event and never changes game state independently.
- Test on low-, mid- and high-tier Android devices; target stable 60 FPS where possible, with a graceful 30 FPS mode.
- No gameplay scrollbars or clipped seats/cards on supported screen sizes.
- Release candidate requires signed Android App Bundle/APK, install/launch smoke tests, audio checks, 4/6-player end-to-end QA and green CI.
- Online multiplayer, secure account sync, server-authoritative rewards/claims and payment integration remain deferred until a separate backend phase.

## 12. Current implementation truth
The existing Flutter project contains a 2D table/card UI, stylized painted portrait avatars, audio hooks, a 1.12-second perspective-rotated card-flight animation, and local 4/6-player game logic. These are not true 3D models or a complete cinematic 3D scene. The draft branch must not be called release-ready until the 3D asset pipeline, runtime scene, event choreography, end-to-end tests and release gates above are implemented and verified.
