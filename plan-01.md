# Rails App Build Plan — Play by Post TTRPG

## Stack

- **Framework**: Ruby on Rails 8 (latest)
- **Database**: PostgreSQL (Railway managed Postgres)
- **UI**: Hotwire (Turbo + Stimulus) + ERB templates
- **Background Jobs**: Solid Queue (Rails 8 default, persists jobs in Postgres — no Redis needed)
- **Auth**: Devise + magic link (devise-passwordless gem)
- **File Storage**: Active Storage + Cloudflare R2 (S3-compatible, generous free tier)
- **Email**: Action Mailer + Mailgun (inbound via ActionMailbox)
- **Markdown**: Redcarpet (rendering) + Stimulus controller for preview
- **Testing**: RSpec + FactoryBot + Capybara
- **Deployment**: Railway (web + worker + Redis + Postgres services)

---

## Phase 1 — Rails Foundation

**Goal:** New Rails app boots, connects to Postgres, has auth, NavBar, and deploys to Railway.

### Tasks

1. `rails new play-by-post --database=postgresql --asset-pipeline=propshaft --skip-action-cable --javascript=importmap` in the current directory
2. Configure `database.yml` for Railway's `DATABASE_URL` env var
3. Add gems: `devise`, `devise-passwordless`, `redcarpet`, `rspec-rails`, `factory_bot_rails`, `capybara`
4. Install Devise with `devise-passwordless` — magic link only (no password)
5. Create `UserProfile` model: `user_id FK, display_name string, last_login_at datetime`
6. After-sign-in hook: upsert UserProfile, update `last_login_at`, redirect to display name setup if blank
7. NavBar partial: display name + sign out link
8. Login page: email field, magic link sent confirmation state
9. First-login display name form (separate page, required before proceeding)
10. Configure Solid Queue — enabled by default in Rails 8, runs in-process via `config.solid_queue.connects_to`
11. `Procfile.dev` for local: `web: bin/rails s` (Solid Queue runs in the web process)
12. Railway config: single `web` service only — no separate worker service needed
13. RSpec setup: `spec/rails_helper.rb`, `spec/support/factory_bot.rb`
14. Deploy to Railway, smoke test magic link flow

---

## Phase 2 — Games & Dashboard

**Goal:** Users can create games, see their dashboard.

### Schema

```
games: id, name, description, created_at, updated_at
game_members: id, game_id, user_id, role (enum: game_master/player), status (enum: active/removed/banned), created_at
```

### Tasks

1. Migrations for `games` and `game_members`
2. `Game` model + validations (name required, max 200 chars)
3. `GameMember` model (role enum, status enum)
4. `GamesController#index` — dashboard: games for current user with active scene count, new activity flag
5. Dashboard view — game cards: name, role, character name (placeholder), active scene count, activity indicator
6. `GamesController#new`, `#create` — game creation form with confirmation
7. After create: insert `game_members` row with `role: :game_master`
8. Model specs for Game, GameMember
9. System spec: create game → lands on game view

---

## Phase 3 — Game View & Scene List

**Goal:** Game page with header, scene list (active + resolved paginated), placeholder sections.

### Schema

```
scenes: id, game_id, parent_scene_id FK self, title, description, private boolean, resolution text, resolved_at datetime, created_at, updated_at
scene_participants: id, scene_id, user_id, last_visited_at datetime, created_at
```

### Tasks

1. Migrations for `scenes` and `scene_participants`
2. `Scene` model + validations, `belongs_to :parent_scene, optional: true`
3. `SceneParticipant` model
4. `GamesController#show` — game header, character roster placeholder, active scenes grouped by parent, resolved scenes (paginated 10/page)
5. Game view: 5-section layout (header, roster placeholder, active scenes, resolved scenes, files placeholder)
6. `SceneCard` partial — title, description excerpt, participant names, last activity, private badge, parent link
7. Parallel scene grouping logic (scenes with same parent on same row)
8. Model specs, system spec: game view renders scenes correctly

---

## Phase 4 — Scene View & Posts

**Goal:** Users can read and write posts in a scene. OOC toggle. Edit window. Scene resolution.

### Schema

```
posts: id, scene_id, user_id, content text, is_ooc boolean default false, last_edited_at datetime, created_at, updated_at
```

### Tasks

1. Migration for `posts`
2. `Post` model + validations, 10-minute edit window method
3. `ScenesController#show` — scene header, post thread, resolution block
4. `PostsController#create` — create post (participant check), Turbo Stream response appends to thread
5. `PostsController#update` — edit post (author only, within 10 min window), Turbo Stream response
6. Scene toolbar: Quick Scene (stub), New Scene (stub), End Scene (GM only), Edit Participants (stub)
7. `ScenesController#resolve` — GM only, sets resolution + resolved_at
8. Post composer: textarea, OOC checkbox, markdown preview toggle (Stimulus controller)
9. `PostItem` partial — author name, timestamp, OOC badge, edit link (10-min window only), markdown rendered content
10. OOC filter toggle (Stimulus controller hides/shows OOC posts)
11. Update `last_visited_at` on scene view load
12. Model specs: edit window enforcement, participant check
13. System spec: post thread renders, create post, OOC filter works

---

## Phase 5 — Scene Creation

**Goal:** Quick Scene and New Scene flows.

### Tasks

1. `ScenesController#new`, `#create` — full scene creation form
2. New Scene form: title, description, participant MultiSelect (checkboxes), parent scene dropdown, private flag
3. Pre-population logic: from scene view (inherit participants + parent), from game view (all players, no parent)
4. Quick Scene: Turbo Frame dialog from scene view — minimal form (title, description only), inherits participants + parent automatically
5. GM always added as participant server-side (cannot be removed)
6. Scene listed in active scenes immediately after creation (Turbo Stream)
7. Participant edit: `SceneParticipantsController#update` — full replacement, GM always included
8. System spec: new scene, quick scene, participant edit

---

## Phase 6 — Invitations, Player Management, Banning

**Goal:** GM can invite players via email, remove, or ban them.

### Schema

```
invitations: id, game_id, invited_by_user_id, email string, token string, accepted_at datetime, created_at
```

### Tasks

1. Migration for `invitations`
2. `Invitation` model — generate secure token on create
3. `InvitationsController#create` — GM only, send invitation email (ActionMailer), `InvitationMailer`
4. `InvitationsController#accept` — validate token, create/link user account, add `game_members` row, redirect with display name setup if needed
5. Player management page: roster with status, pending invitations (resend/cancel)
6. `GameMembersController#update` — remove (status: removed) or ban (status: banned)
7. Access control: removed players get read-only (enforced in controllers), banned players get 403 everywhere
8. Dashboard: removed players see game with "Former" badge; banned players don't see game
9. Model specs: invitation token generation, membership status scopes
10. System spec: invite flow end-to-end, remove player, ban player

---

## Phase 7 — Characters & Version History

**Goal:** Characters per game per player, version history, GM can edit any sheet.

### Schema

```
characters: id, game_id, user_id, name string, content text, active boolean default true, hidden boolean default false, created_at, updated_at
character_versions: id, character_id, content text, edited_by_user_id, created_at
```

### Tasks

1. Migrations for `characters` and `character_versions`
2. `Character` model + `CharacterVersion` — after_save callback creates version snapshot
3. `CharactersController` — CRUD, GM can access any character in game, player owns their own
4. Character sheet view: monospaced pre-wrap content, version history collapsed panel
5. Character creation dialog (from game view roster) — name required, content starts empty
6. GM-on-behalf creation
7. Inactive/hidden flags — inactive hidden from roster by default (toggle to show), hidden from other players (GM always sees all)
8. `games.sheets_hidden` flag — GM toggle to hide all sheets from non-GM players
9. Dashboard: character name linked to sheet
10. Model specs: visibility rules, version snapshot
11. System spec: create character, edit sheet, view version history

---

## Phase 8 — File Storage (Active Storage + R2)

**Goal:** Game files upload (GM only). Image attachments on posts and scenes.

### Tasks

1. Configure Active Storage with Cloudflare R2 (`config/storage.yml`, R2 credentials in env)
2. `GameFile` model — `has_one_attached :file`, GM only, 25MB limit, allowed types
3. `GameFilesController` — upload, list, delete (GM only)
4. Game files section in game view — file list with metadata, upload form
5. Post image attachment — `has_one_attached :image`, 5MB limit, allowed types
6. Scene image attachment — same
7. Image display in post/scene view (thumbnail, click to expand via Stimulus)
8. Model specs: file type/size validation
9. System spec: upload game file, attach image to post

---

## Phase 9 — Email Notifications

**Goal:** Outbound email for new scene, post digest, scene resolution, invitation, magic login.

### Tasks

1. Configure ActionMailer with Mailgun SMTP
2. `NotificationMailer` — new scene email, scene resolution email
3. `InvitationMailer` — invitation email with magic link (already partially in Phase 6)
4. `notification_preferences` table — `scene_id, user_id, muted boolean default false`
5. `NotificationPreference` model — opt-out model (no record = notifications on)
6. `PostDigestJob` (Sidekiq) — find participants with `last_visited_at` > 24h ago, send digest email with up to 10 posts + "and N more..."
7. Digest cron: Solid Queue recurring task in `config/recurring.yml`, runs daily
8. Notification preference toggle — in scene view and game view scene cards
9. All notification sends check preference before delivering
10. Reply-to routing: encode scene ID in reply-to address (`scene-{id}@inbound.domain`)
11. Email templates — all 5 types styled with consistent layout
12. System spec: digest job sends correct emails, preference mute is respected

---

## Phase 10 — Inbound Email (ActionMailbox)

**Goal:** Reply to a notification email creates a post in the scene.

### Tasks

1. Configure ActionMailbox with Mailgun inbound webhook
2. `SceneMailbox` — route by reply-to address pattern `scene-{id}@...`
3. Validate sender is an active scene participant
4. LLM call (OpenRouter, `google/gemma-3-4b-it:free`) to strip email artifacts (quoted replies, signatures)
5. Create post from cleaned content (always in-character, no OOC via email)
6. Error handling: unrecognized sender → bounce/ignore; LLM failure → create post with raw content
7. Spec: mailbox routing, participant validation, post creation

---

## Phase 11 — Polish & Hardening

**Goal:** Production-ready: error handling, logging, pagination, access control audit.

### Tasks

1. ApplicationController error handling — rescue from common exceptions, render appropriate responses
2. Authorization audit — every controller action checks membership status
3. Pagination on resolved scenes (already Kaminari or Pagy)
4. Turbo Stream flash messages for success/error feedback
5. Responsive layout pass (Hotwire-friendly, no JS framework)
6. `config/initializers/content_security_policy.rb` — tighten CSP for production
7. Health check endpoint `GET /up` (Rails 8 default)
8. Railway deploy: environment variables documented, Procfile verified, migrate on deploy

---

## Notes

- **No PrimeReact** — this is Rails/Hotwire. Use plain HTML + minimal CSS (Pico CSS or similar classless framework fits the "information first" aesthetic from the designs).
- **PostgreSQL enum types** — use Rails string columns with `enum` declarations (avoids Postgres enum migration complexity).
- **RLS** — not applicable in Rails context; access control is in controllers/models.
- **LLM in Phase 10** — keep the OpenRouter integration in a plain Ruby service object, injected into the mailbox.
- **R2 vs Supabase Storage** — Cloudflare R2 has a permanent free tier (10GB storage, 1M requests/month), fits the usage scale.
