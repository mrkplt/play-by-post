# Plan 1 — Teardown: remove the RSS implementation

**Branch:** `26-rss-teardown` · One PR.

Delete the RSS token model, the feed-delivery path, and the token-management UI.
`scene_summaries#index` becomes members-only HTML with **no anonymous and no token
access**. Pure removal — no new architecture. Build-up lands in Plan 2.

## Guiding constraint (from the owner)

**Keep layouts consistent.** The previous (reverted) attempt removed too many shared
visual elements it guessed were no longer needed. Do NOT strip consistent chrome here:
the scene_summaries index footer (`Shared::PageActionsComponent`) stays present — an
**empty footer / empty primary slot is acceptable**. Remove only the RSS button itself,
not the footer structure around it.

## Behavior after this PR

- `GET /games/:id/scene_summaries` (HTML) — signed-in **active members only**; everyone
  else redirected to sign-in. (Already the effective HTML behavior; we remove the token
  escape hatch and the `skip_before_action`.)
- `GET /games/:id/scene_summaries.rss` — **gone.** The `.rss` format no longer routes to
  a feed; the RSS renderer is deleted.
- Profile page — no RSS Token section.
- No `rss_tokens` table, no `RssToken` model, no generate/revoke routes.

## Changes

### Routing / controller
1. `config/routes.rb`
   - Remove `post :generate_rss_token` (line 30) and `delete :revoke_rss_token`
     (line 31) from the `resource :profile` block.
   - Move the standalone `scene_summaries` index (lines 85–88, currently **outside**
     `authenticate :user`) **into** the `authenticate :user` block so the route itself
     requires a session. Delete the "accessible with RSS token (no session required)"
     comment.
2. `app/controllers/scene_summaries_controller.rb`
   - Remove `skip_before_action :authenticate_user!, only: [:index]` (line 6).
   - Add `:index` to the existing `before_action :require_game_access!` list so
     membership is enforced by the standard guard.
   - Collapse `index` to HTML-only: drop the whole `respond_to`/`format.html`/`format.rss`
     structure. Keep the summary-loading + `pagy` + `@game_presenter`. The inline
     `unless user_signed_in? && game_access_granted?` guard is now redundant with
     `require_game_access!` — remove it.
   - Delete `rss_access_allowed?` (lines 139–151).
   - Keep `after_action :verify_authorized, except: :index` (index is a membership-gated
     listing, authorizes no record). Confirm `bin/check-authorization` still passes
     (task 12).

### Model / data
3. Delete `app/models/rss_token.rb`.
4. `app/models/user.rb:21` — remove `has_one :rss_token, dependent: :destroy`.
5. New migration `DropRssTokens` — `drop_table :rss_tokens` with a reversible block
   mirroring the original `create_table` (columns, both unique indexes, the users fk).
   Run it; commit the updated `db/schema.rb`.
6. Delete `sorbet/rbi/dsl/rss_token.rbi`. Run `bundle exec tapioca dsl` to reconcile;
   `git checkout --` any unrelated RBI it disturbs (tapioca reconciliation trap).

### Views / components
7. Delete `app/views/scene_summaries/index.rss.builder`.
8. `app/views/scene_summaries/index.html.erb`
   - Remove the "RSS Feed" `Ui::ButtonComponent` in the `with_primary` slot (line 14).
   - **Keep the `PageActionsComponent` footer.** Leaving `with_primary` empty is fine.
     For the GM, the "Edit Game" `with_cancel` secondary stays. Do NOT delete the footer
     or the `frame.with_footer` block — layout stays consistent across screens.
9. Delete `app/components/shared/rss_token_component.rb` + `.html.erb`.
10. `app/views/profiles/show.html.erb:27–29` — remove the `RSS Feed Token`
    `SectionLabelComponent` + `Shared::RssTokenComponent` render.

### Registration / docs / checks
11. `.mutant.yml` — remove `RssToken` (line 22) and `Shared::RssTokenComponent` (line 50).
12. `bin/check-authorization:28` — remove the `scene_summaries_controller.rb` allowlist
    entry ("index is a public / RSS listing with its own access rules"). Index is now
    membership-gated with `verify_authorized except: :index`. Run the script; if it
    demands an `authorize` call in `index`, add `skip_authorization` with a one-line
    comment rather than authorizing a record.
13. `docs/AUTHORIZATION.md` — update the `scene_summaries` row (line 336) and the stale
    `:106-108` / `:115` / `:153` line references to reflect the collapsed controller.
    Drop the RSS-listing / public-access language.

### Specs
14. Delete `spec/models/rss_token_spec.rb` and `spec/factories/rss_tokens.rb`.
15. `spec/requests/scene_summaries_spec.rb`
    - Delete the entire `GET /games/:game_id/scene_summaries.rss` describe block
      (lines 116–146).
    - HTML block: `"redirects unauthenticated users"` (30–33) and `"redirects a removed
      member who is not signed in"` (50–55) stay and assert redirect to sign-in.
    - In `"renders visible text on the RSS Feed and Edit Game page-action buttons"`
      (100–105): remove the `">RSS Feed<"` assertion, keep `">Edit Game<"`. Rename the
      example accordingly.
16. `spec/requests/profiles_spec.rb` — delete the `POST /profile/generate_rss_token`
    (87–110) and `DELETE /profile/revoke_rss_token` (113–133) describe blocks.
17. `spec/components/ui/settings_row_component_spec.rb:18` — **leave as-is.** The
    "RSS Token" string is generic placeholder text for a reusable component, not an RSS
    dependency. Noted so it is not "cleaned up" by mistake.

## Verification
- `bin/pre-push` (rubocop, design-tokens, mutant-registration, srb tc, brakeman,
  unit specs).
- `grep -ri rss app lib config db spec` returns nothing but the innocuous
  `settings_row_component_spec` placeholder.
- Mutation `--since origin/master` pulls `SceneSummariesController` into scope (task 2
  edits it) — keep/write index HTML tests that hold the subject above the mutation floor.
- Full `bundle exec rspec` green **before** `bin/quality-metrics --check` (a mutation run
  overwrites line coverage — re-run rspec if mutation ran last).

## Notes
- No ERB ternary / `||` / local-assign in output tags; extract to
  presenter/component/helper methods if any logic is needed.
- Every touched `app/`/`lib/` file needs its Sorbet sigil and must clear the coverage
  gate (≥80% line, ≥70% branch).
