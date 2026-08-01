# Plan: Per-game-per-user RSS tokens + copyable feed URL

## Current state
- `RssToken`: one per user (unique `user_id`), `User has_one :rss_token`.
- Feed auth (`scene_summaries#index`, `rss_access_allowed?`): find token → check its
  user is an active member of the requested game. So one token works for ALL the
  user's games.
- UI (`Shared::RssTokenComponent` on profile): shows the raw token in a `<code>`
  block, generate/rotate/revoke. No feed URL shown at all.

## Target (user-confirmed)
Tokens are scoped **per user per game**. A token is a specific game's feed
credential.

- **Data:** `rss_tokens` gains `game_id` (not null, fk); unique index
  `(user_id, game_id)` (replaces the unique `user_id` index). `User has_one
  :rss_token` → `has_many :rss_tokens`; `Game has_many :rss_tokens`.
- **Existing tokens:** dropped in the migration (users regenerate per game).
  Existing feed URLs break by design.
- **Auth:** `RssToken.find_by(token:)` must have `game_id == @game.id` AND the
  user is still an active member of that game. A token for game A is invalid on
  game B. Signed-in active members still bypass via session (unchanged).
- **Management:** all on the profile page. List every game the user belongs to
  (non-banned); per game: generate / rotate / revoke, and when a token exists
  show the **full feed URL** (`game_scene_summaries_url(game, format: :rss,
  token: token)`) in a copyable, masked field.
- **Feed URL:** `/games/:game_id/scene_summaries.rss?token=TOKEN`.

## New reusable component
`Ui::SecretFieldComponent(value:, label:)`:
- Read-only text field showing `value`, **masked by default** (dots).
- Visibility toggle (show/hide the real value).
- Copy-to-clipboard button (always copies the real value).
- Small Stimulus controller (`secret-field`) for toggle + copy; CSS in the
  component. Register in `.mutant.yml`. Strict Sorbet.

## Code
- Migration: add `game_id`, drop old unique `user_id` index + add
  `(user_id, game_id)` unique; delete existing rows.
- `RssToken`: `belongs_to :game`; scope/finder per (user, game); keep secure
  token gen; `regenerate!`.
- `User`: `has_many :rss_tokens`. `Game`: `has_many :rss_tokens, dependent:
  :destroy`.
- `ProfilesController#generate_rss_token` / `#revoke_rss_token`: take a `game_id`,
  operate on that game's token (guard membership). `#show` loads memberships +
  their tokens.
- `scene_summaries#rss_access_allowed?`: require `rss_token.game_id == @game.id`.
- Profile view: replace `Shared::RssTokenComponent` usage with a per-game list;
  each row uses `Ui::SecretFieldComponent` for the feed URL when a token exists,
  plus generate/rotate/revoke buttons. Update/replace `Shared::RssTokenComponent`.
- Routes: `generate_rss_token` / `revoke_rss_token` need a game param (member
  route on games, or pass game_id).
- `REQUIREMENTS.md`, specs (model, request, component, system), `.mutant.yml`,
  Sorbet, full gate.

## Notes
- No ERB ternary/`||`; presenter/helper/component methods for any logic.
- Feed-URL building uses `_url` (absolute) with the app host.
