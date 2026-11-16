# LORIS online multiplayer foundation

This folder defines the backend-independent contract and public data models for
4-player and 6-player online rooms. It does **not** connect to a live server yet.

## Contract

- Create a room and receive a six-character invite code.
- Join by invite code; reserve a unique seat for each authenticated player.
- Watch public room state and a monotonically sequenced event stream.
- Ready up, submit actions, leave, and recover by requesting events after the
  last acknowledged sequence.
- Keep private hands in player-scoped server data. Never put hands in
  `OnlineRoom`, public room broadcasts, logs, or leaderboard responses.

## Required backend behavior before production

1. Authenticate every player and derive player identity from the verified
   session, never from a client-supplied player ID alone.
2. Enforce room capacity (exactly 4 or 6), unique seats, host permissions,
   room-code expiry/rate limits, and reconnect grace periods.
3. Make the server authoritative for dealing, bidding, trump selection,
   legal card play, LORIS rules, trick resolution, and score calculation.
4. Validate every action against the current turn and expected sequence;
   reject duplicates, stale commands, illegal moves, and forged scores.
5. Broadcast only public state to the room. Deliver each player's hand through
   a private authenticated channel.
6. Persist match results transactionally. Only verified completed matches may
   award XP, season points, or leaderboard rating.
7. Add rate limits, audit logs without private card data, moderation/reporting,
   backups, monitoring, and account deletion/export flows.

## Suggested integration sequence

- Provision a hosted realtime database/backend and configure its URL and
  public client key through build-time environment configuration.
- Implement `OnlineRoomService` using authenticated room membership and
  server-side functions. Never commit service-role keys or other secrets.
- Add account/profile, room lobby, reconnect, and online match UI.
- Add server-owned XP, levels, seasonal rating, leaderboard, and premium
  entitlement records after match validation is working.
- Add integration tests with multiple independent clients and adversarial
  invalid-action tests before enabling public matchmaking.

## Current status

The Dart contracts and validation models are ready for integration. A live
backend, authentication, realtime adapter, online UI, accounts, seasons,
leaderboards, XP progression, and premium billing are not yet connected.
