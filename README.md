# LORIS — The Ultimate Card Game

A Flutter card game for Android and web, with offline play against AI.

## Game modes

- **4 players:** 32-card deck (7 through Ace in each suit); the Spades 7 is replaced by the LORIS card.
- **6 players:** 48-card deck (3 through Ace in each suit); the Spades 3 is replaced by the LORIS card.
- Teams sit alternately: A-B-A-B or A-B-A-B-A-B.
- Each player receives eight cards.
- The first player to receive a Jack during the dealer-selection draw becomes the dealer.

## Core rules implemented

- Bidding from 4 to 8, starting to the dealer's right.
- The highest bidder chooses trump from a card held by their team.
- Players must follow the led suit when possible.
- If void in the led suit, a player must trump when holding trump.
- If a higher trump can beat the highest trump already played, overtrumping is compulsory.
- LORIS may be played at any time and is the highest card; it cannot be overtrumped.
- The last-trick winner is offered CALL 16 or PASS immediately when the bidding team reaches exactly its bid, but only if that team has won every trick since the round began. One opponent trick permanently disables the option for that round. PASS closes the one-time option; CALL 16 requires the bidding team to win every remaining trick, otherwise the round ends at -16 for them and +16 for opponents.
- A successful bid scores its bid amount; a successful 8-call (all eight tricks) scores 16 points. An unsuccessful bid awards the opposing team double the bid.
- The match target is 32 points.
- Saved matches can be resumed on the same device.

## Development and verification

GitHub Actions runs Flutter analysis, automated tests, and an Android debug APK build. A separate workflow builds and deploys the web version to GitHub Pages.

- Run locally: `flutter pub get`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Android APK: `flutter build apk --release`
- Web: `flutter build web --release --base-href "/Loris-Card-Game--/"`

## Current scope and planned work

The current playable mode is one human player against AI opponents, with offline local save/resume. AI bidding uses only its own hand; AI card play uses its own hand plus public trick state; AI trump selection now uses only the bidder's own hand and does not inspect hidden teammate cards. Audio and visual polish are partially integrated. Keep existing stylized 2D player portraits—**3D human avatars and facial animation are explicitly out of scope**. Visual work should focus on a polished table, genuine 3D table/card rendering where feasible, clear UI, card art, animations, audio and settings. Human avatar work is removed from scope: do not spend development time on 3D avatars, facial animation, face rigging or character animation. Retain the existing 2D portraits. Prioritize card readability, table/card effects, animation timing, audio controls and gameplay polish. Background music is not connected yet; do not imply the music toggle plays a soundtrack until it is wired to actual audio. Online/Bluetooth multiplayer, backend accounts and sync, server-authoritative rewards, payments, signed release distribution, and physical-device QA are not established as complete.
