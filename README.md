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
- A valid 16 call requires the bidding team to have reached its bid and won the previous trick; after the call, the team must win every remaining trick.
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

The current playable mode is one human player against AI opponents, with offline local save/resume. Offline Bluetooth multiplayer, richer AI strategy, audio, and final production polish remain development tasks and are not represented as completed features.
