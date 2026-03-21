# Next Steps

## Setup & Deployment

### 1. Local development
- [x] `bin/rails server` boots at http://localhost:3000
- [x] letter_opener configured for magic link emails in development

### 2. Git + GitHub
- [ ] `git init`, initial commit, push to GitHub

### 3. Deploy to Railway
- [ ] Create Railway project with managed PostgreSQL
- [ ] Connect GitHub repo to Railway web service
- [ ] Set environment variables: `SECRET_KEY_BASE`, `RAILS_ENV=production`, `APP_HOST`
- [ ] Verify `railway.toml` runs `db:migrate` on deploy

### 4. Mailgun
- [ ] Sign up, verify domain
- [ ] Set `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` in Railway env vars
- [ ] Configure inbound route: `scene-*@inbound.yourdomain.com` → ActionMailbox endpoint
- [ ] Set `RAILS_INBOUND_EMAIL_PASSWORD` in both Mailgun and Railway

### 5. Cloudflare R2 (file storage)
- [ ] Create R2 bucket
- [ ] Set `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_ENDPOINT` in Railway
- [ ] Add `gem "aws-sdk-s3", require: false` to Gemfile
- [ ] Configure `config/storage.yml` for R2 in production

### 6. OpenRouter (inbound email LLM parsing)
- [ ] Set `OPENROUTER_API_KEY` in Railway env vars (app degrades gracefully without it)

---

## Implementation Order

Items are ordered by dependency and risk. Item 10 must come first because the
`require_active_member!` helper it introduces is needed by items 9a and 8b.

| Priority | Item | Status |
|----------|------|--------|
| 1 | 10 — Access control | DONE |
| 2 | 7a — sheets_hidden | DONE |
| 3 | 7b — Toolbar test | DONE |
| 4 | 8b — GameFiles access fix + view + specs | DONE |
| 5 | 8 — Model stubs | DONE |
| 6 | 7c — Digest job specs + cron | DONE |
| 7 | 7d — Mailbox specs | DONE |
| 8 | 11 — Profile show | DONE |
| 9 | 9a — Join scene | DONE |
| 10 | 9b — Image attachments | DONE |

---

## Access Control Fixes

### 10. Former player behavior (removed/banned enforcement) — DONE

**Tasks:**
- [x] Run `rspec spec/system/games_spec.rb` to verify dashboard/Former badge already works
- [x] Add `require_active_member!` helper to `ApplicationController`
- [x] Add `before_action :require_active_member_for_write!` to `PostsController` (create)
- [x] Add `before_action :require_active_member_for_write!` to `CharactersController` (new, create, edit, update)
- [x] Verify post composer is hidden for removed players (already gated in view)
- [x] Verify banned players are blocked from all game/scene access (already gated by `require_game_access!`)
- [x] Add specs (new `spec/system/access_control_spec.rb`):
  - Removed player sees game on dashboard with "Former" badge
  - Removed player cannot post in a scene (server-side enforcement)
  - Removed player can view scenes and posts (read-only)
  - Removed player cannot create or edit a character
  - Banned player does not see game on dashboard
  - Banned player cannot access the game directly

---

## Feature Work

### 7a. `sheets_hidden` game flag — DONE

**Tasks:**
- [x] Update `Character.visible_to` scope to respect `game.sheets_hidden?`
  - GM sees all characters regardless
  - When `sheets_hidden`, non-GM players see only their own characters
- [x] Add GM toggle action: `GamesController#toggle_sheets_hidden`
- [x] Add route: `patch :toggle_sheets_hidden, on: :member` inside games resources
- [x] Add toggle button to game view (GM only)
- [x] Add model specs to `spec/models/character_spec.rb` under `describe ".visible_to"`
- [x] Add system specs to `spec/system/characters_spec.rb`:
  - `sheets_hidden` hides other players' characters from non-GM
  - `sheets_hidden` still shows own character to the player
  - GM can toggle sheets_hidden

### 7b. Scene toolbar hidden after resolution — DONE

**Tasks:**
- [x] Add spec to `spec/system/scenes_spec.rb` (scene resolution describe block):
  - Hides Scene actions menu after resolution

### 7c. `PostDigestJob` — specs + cron schedule — DONE

**Tasks:**
- [x] Write real specs in `spec/jobs/post_digest_job_spec.rb`:
  - Sends digest to participants who haven't visited in 24 hours
  - Does not send to muted participants
  - Does not send to participants who visited recently
  - Does not send when participant authored the only recent post
- [x] Verify cron schedule in `config/recurring.yml` (already configured)
- [x] Fix `deliver_later` serialization bug (`.to_a` on relation)

### 7d. Inbound email / scene mailbox — specs — DONE

**Tasks:**
- [x] Verify `EmailContentExtractor` falls back gracefully without API key
- [x] Verify `application_mailbox.rb` routing is in place
- [x] Write real specs in `spec/mailboxes/scene_mailbox_spec.rb`:
  - Creates a post from an inbound email by a participant
  - Bounces email from a non-participant
  - Bounces email to an unknown scene
- [x] Fix `bounce_with` to use `inbound_email.bounced!` directly (custom bounce classes didn't implement `deliver_later`)

### 8. Pending model spec stubs — DONE

**Tasks:**
- [x] `spec/models/user_profile_spec.rb` — replace pending stub with real specs
- [x] `spec/models/user_spec.rb` — replace pending stub with real specs

### 8b. Game files — access control fix + view + specs — DONE

**Tasks:**
- [x] Fix `GameFilesController` access control: `require_gm!` only on `create`/`destroy`, add `require_game_access!` for all actions
- [x] Add `@game_files` to `GamesController#show`
- [x] Replace placeholder in `games/show.html.erb` with inline file list (download links for all, manage link for GM)
- [x] Add model spec for `GameFile` (type validation, size validation)
- [x] Add system spec for game files (non-GM can view, GM sees upload/delete, banned blocked)

---

## New Features

### 9a. Add player to existing scene — DONE

**Tasks:**
- [x] Add `join` route inside participants resource
- [x] Add `join` action to `SceneParticipantsController` with private-scene and resolved-scene guards
- [x] Add `@current_membership` to `ScenesController#show`
- [x] Add "Join Scene" button to scene view for non-participant active members on non-private scenes
- [x] Add specs to `spec/system/scenes_spec.rb`:
  - Player can join a non-private scene
  - Join button hidden from existing participants
  - Join button hidden on resolved scenes
  - Join button hidden from GM
  - Join button hidden on private scenes

### 9b. Image attachments on posts and scenes — DONE

Uses `image_processing` gem with libvips backend. On-the-fly variant generation
(lazy, cached to storage after first request). Falls back to serving originals
when vips is not available (e.g., local dev without libvips installed).

Variant dimensions: Post display 800px wide, Scene banner 1200px wide, both JPEG quality 85.

**Tasks:**
- [x] Enable `image_processing` gem (uncommented in Gemfile)
- [x] Add `validate :acceptable_image` to `Post` model (type + 10 MB size check)
- [x] Add `validate :acceptable_image` to `Scene` model (type + 10 MB size check)
- [x] Add named variant methods: `Post#display_image`, `Scene#banner_image`
- [x] Add `multipart: true` and file field to post composer
- [x] Add error display to post composer partial
- [x] Add `:image` to `PostsController#post_params`
- [x] Render image in `_post_item.html.erb` via `post.display_image`
- [x] Add `multipart: true` and file field to scene creation form
- [x] Add `:image` to `ScenesController#scene_params`
- [x] Render scene banner image in `scenes/show.html.erb` via `@scene.banner_image`
- [x] Add model specs for image validation (Post and Scene)
- [x] Add system specs for image upload and display

---

## Profile

### 11. Player profile page (`profiles#show`) — DONE

**Tasks:**
- [x] Add `show` action to routes: `resource :profile, only: %i[show edit update]`
- [x] Add `ProfilesController#show`
- [x] Create `app/views/profiles/show.html.erb` showing: display name, games with role, preferences
- [x] Update navbar link from `edit_profile_path` to `profile_path`
- [x] Add "Cancel" link on edit page back to `profile_path`
- [x] Add specs for profile show page:
  - User sees display name and game list
  - Edit link navigates to edit page
  - Navbar links to profile show
  - Cancel link on edit page

---

## End-to-End Smoke Test — DONE (covered by system specs)

### 12. Verification checklist — all items covered by automated specs
1. Start server locally — (infrastructure, not testable)
2. Sign in flow — `spec/system/sign_in_spec.rb`
3. Magic link — `spec/system/sign_in_spec.rb`
4. Set display name — `spec/system/profiles_spec.rb`
5. Create a game — `spec/system/games_spec.rb`
6. Create a scene — `spec/system/scenes_spec.rb`
7. Post in the scene — `spec/system/posts_spec.rb`
8. Edit window — `spec/system/posts_spec.rb`
9. Invite/accept — `spec/system/player_management_spec.rb`
10. Character CRUD + versions — `spec/system/characters_spec.rb`
11. Scene resolution — `spec/system/scenes_spec.rb`
12. Mute/unmute + digest suppression — `spec/system/scenes_spec.rb`
13. Upload game file via form — `spec/system/game_files_spec.rb`
14. Removed player access — `spec/system/access_control_spec.rb`
15. Banned player access — `spec/system/access_control_spec.rb`
