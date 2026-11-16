# LORIS online backend (Supabase)

This folder contains the first database migration for online rooms, player identity,
public match events, private hands, and seasonal results.

## What the migration provides

- Authenticated player profile rows.
- Four- and six-player waiting rooms with six-character room codes.
- Seat membership, readiness, host handoff, and leave-room RPC functions.
- Public event envelopes with per-room sequence numbers.
- Private hands in a separate table; a player can read only their own hand.
- Season and season-result tables for future leaderboard screens.
- Realtime publication for room metadata, seats, and public events.
- Client permissions that prevent players from editing their own XP, rating,
  or Premium entitlement.

## Create and configure the Supabase project

1. Create a Supabase project and enable an authentication provider (email/password
   is sufficient for the first integration).
2. Install the Supabase CLI and authenticate:
   `supabase login`
3. Link this repository to the project:
   `supabase link --project-ref YOUR_PROJECT_REF`
4. Apply the migration:
   `supabase db push`
5. In Supabase Dashboard, confirm Realtime is enabled for
   `loris_rooms`, `loris_room_players`, and `loris_game_events`.
6. Configure the Flutter app with the project URL and publishable/anon key using
   build-time configuration. Never put the service-role key in the mobile app.

## RPC functions

- `loris_create_room(requested_mode, requested_display_name, requested_avatar_id)`
- `loris_join_room(requested_room_code, requested_display_name, requested_avatar_id)`
- `loris_set_ready(requested_room_id, requested_ready)`
- `loris_leave_room(requested_room_id)`

All four functions require an authenticated Supabase user.

## Important security boundary

The migration is a room/profile foundation, not a complete authoritative card-game
server. Do not let clients insert or update `loris_game_events` or
`loris_private_hands`. Before enabling competitive public matchmaking, implement
a trusted Edge Function or server that validates every bid, trump choice, card
play, follow-suit/overtrump rule, trick result, score, and event sequence. The
server must deal cards and write each private hand separately. Premium status,
XP, ratings, and season results must also be changed only by trusted server code.

## Flutter integration status

The current Flutter app has backend-independent room and progression models plus
an `OnlineRoomService` interface. It is not connected to a Supabase project yet.
The project URL and public client key are required to finish live authentication,
room subscriptions, and lobby UI integration. No service-role secret should be
shared or committed.
