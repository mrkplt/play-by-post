# Player Contributions (Fizzy #18)

A GM-controlled setting lets **active players** create pages, links, and uploaded
files in a game. Default is **off**. Players may delete their **own** contributions
while the setting is on; GMs may delete **any** contribution.

## Setting

- New game boolean `player_contributions_enabled`, default `false`.
- Flipped from Edit Game via the same in-place toggle plumbing as AI Summaries /
  Sheets Hidden (`Games::SettingsController`, `GameSettingToggle`,
  `Shared::GameFlagToggle`). Route `toggle_player_contributions_enabled_game_path`.
- GM-only flip (`authorize game, :manage?`).

## Authorization matrix (per resource: Page, GameLink, GameFile)

| Actor | Setting off | Setting on |
|---|---|---|
| GM | create ✔ · delete any ✔ | create ✔ · delete any ✔ |
| Active player | create ✗ (403) · delete own ✗ | create ✔ · delete own ✔ |
| Active player, other's record | — | delete ✗ (403) |
| Removed / banned member | create ✗ · delete ✗ | create ✗ · delete ✗ |
| Non-member | 404/redirect | 404/redirect |

- `create?` → GM **or** (active member **and** `game.player_contributions_enabled?`).
- `destroy?` → GM **or** (active member **and** `game.player_contributions_enabled?`
  **and** actor authored the record). Turning the setting **off** revokes players'
  delete-own (owner's decision, card #18 clarification).

## Creator attribution

- **Page** — authorship is the earliest `PageVersion.edited_by_id` (existing
  `Page.created_by` scope). No schema change.
- **GameLink / GameFile** — new `created_by_id` (FK users), **NOT NULL**. The migration
  adds it nullable, backfills existing rows to the game's GM, then enforces NOT NULL;
  new rows are stamped with the acting user on create.

## Manual verification

1. As GM, open Edit Game → the Player Contributions toggle shows, default off.
   Flip it on: toast + control swaps in place, no reload. Reload: still on.
2. As an active player with setting **off**: no "New Page"/"Add Link"/"Upload"
   affordance; hitting the create route directly redirects/403s.
3. Flip **on**. As the active player: create a page, a link, upload a file — each
   succeeds and is attributed to them.
4. As that player: delete each of their own contributions — succeeds in place.
5. As that player: attempt to delete the GM's page/link/file → denied.
6. As GM: delete the player's contributions → succeeds.
7. Flip **off** again: the player's create affordances disappear and their
   delete-own is denied; the GM can still delete everything.
8. Removed and banned members: no create, no delete, in both toggle states.

## Both viewports

Exercise the toggle and the create/delete affordances at mobile (<1024px) and
desktop (≥1024px) — the affordances render in the game show page sections and the
files/links index components.
