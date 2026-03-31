# CLAUDE.md

## Project Overview

Play-by-Post TTRPG is a Rails 8 web application for asynchronous tabletop role-playing games. Game masters and players collaborate on scenes through threaded posts, with email notifications and reply-by-email functionality.

## Documentation

- [Domain](../context/domain.md) — concepts, data model relationships, business rules
- [Product Requirements](../context/pbp_ttrpg_requirements.md)

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Framework | Rails 8.1.3 |
| Language | Ruby 4.0.2 |
| Database | PostgreSQL (production), SQLite3 (dev/test) |
| Asset Pipeline | Propshaft |
| CSS | Tailwind CSS (migration from vanilla CSS in progress) |
| Icons | HugeIcons via `icons` gem (Rails Designer) |
| Frontend JS | Hotwire (Turbo + Stimulus) + Importmap (ESM, no bundler) |
| UI Components | ViewComponent + Draper decorators |
| Markdown | Redcarpet rendering + Stimulus live preview |
| Auth | Devise + devise-passwordless (magic link) |
| File Storage | Active Storage + Cloudflare R2 (production) |
| Background Jobs | Solid Queue (database-backed, no Redis) |
| Caching | Solid Cache (database-backed) |
| Email (outbound) | ActionMailer + Mailgun |
| Email (inbound) | ActionMailbox (reply-by-email → posts) |
| Pagination | Pagy |
| Testing | RSpec + FactoryBot + Capybara + Playwright |
| Type Checking | Sorbet (gradual typing) |
| Linting | RuboCop (Omakase style) |
| Security | Brakeman (static analysis) |
| Coverage | SimpleCov (line + branch) |
| Mutation Testing | Mutant |
| Deployment | Railway.app + Docker |

---

## Codebase Structure

```
app/
  controllers/       # REST controllers, one per resource
  models/            # 13 ActiveRecord models
  views/             # ERB templates
  components/        # ViewComponent library (UI components)
  presenters/        # Presenter objects wrapping models for display logic
  services/          # Service objects (email parsing, markdown rendering)
  mailers/           # ActionMailer (outbound email)
  mailboxes/         # ActionMailbox (inbound email → posts)
  jobs/              # ActiveJob (post digest, notifications)
  javascript/
    controllers/     # Stimulus controllers
  assets/
    stylesheets/     # application.css (legacy vanilla CSS, ~537 lines)
    tailwind/        # application.css (new Tailwind config)
    builds/          # generated CSS output (do not edit)
    icons/           # HugeIcons SVGs

config/
  routes.rb          # All routes (see Routes section below)
  database.yml       # SQLite dev/test, PostgreSQL production

db/
  schema.rb          # Authoritative schema (never edit migrations after merge)

spec/
  system/            # End-to-end tests (Capybara + Playwright)
  models/            # Model unit tests
  controllers/       # Request specs
  components/        # ViewComponent specs
  presenters/        # Presenter unit tests
  services/          # Service object specs
  mailers/           # Email generation specs
  mailboxes/         # Inbound email specs
  jobs/              # Background job specs
  factories/         # FactoryBot factories (11 files)
  support/           # Test helpers (auth, Capybara config)

tests/integration/   # Manual testing plans (markdown files, not RSpec)

bin/
  pre-push           # Full quality pipeline (lint → security → types → tests → mutation → metrics)
  quality-metrics    # Coverage/mutation/typing metric collector and baseline checker

sorbet/              # Sorbet RBI files and configuration
.github/workflows/   # CI/CD (ci.yml)
```

---

## Domain Model

### Core Entities

- **User** — Magic link auth (no passwords). Has many games (through game_members), posts, characters.
- **UserProfile** — display_name, hide_ooc preference, last_login_at.
- **Game** — Container for a campaign. name (max 200 chars), description.
- **GameMember** — Joins users to games. `role` enum: `game_master` | `player`. `status` enum: `active` | `removed` | `banned`.
- **Scene** — Narrative unit within a game. Supports hierarchical parent/child structure. Has optional image attachment. `resolved_at`, `private` flag.
- **SceneParticipant** — Tracks which users are in which scenes (`last_visited_at`).
- **Post** — Content in a scene. Markdown body. Optional image attachment. Editable within 10-minute window (`editable_by?`).
- **Character** — Game character with name, markdown content, `archived_at`, `hidden` flag.
- **CharacterVersion** — Snapshot of character content at a point in time.
- **GameFile** — File attachment (PDF/image) attached to a game via Active Storage.
- **Invitation** — Email invitation to join a game. Has token, `accepted_at`.
- **NotificationPreference** — Per-user, per-scene email notification setting.

### Key Relationships

```
User → GameMember → Game → Scene → Post
                         → GameFile
                         → Character → CharacterVersion
                         → Invitation
User → SceneParticipant → Scene
User → NotificationPreference → Scene
```

---

## Routes

All authenticated routes require `authenticate :user`. Root is `games#index`.

```
GET  /                            games#index
GET  /games/new                   games#new
POST /games                       games#create
GET  /games/:id                   games#show
GET  /games/:id/edit              games#edit
PATCH/PUT /games/:id              games#update
PATCH /games/:id/toggle_sheets_hidden
PATCH /games/:id/toggle_images_disabled

GET  /games/:game_id/scenes       scenes#index
POST /games/:game_id/scenes       scenes#create
GET  /games/:game_id/scenes/:id   scenes#show
PATCH /games/:game_id/scenes/:id/resolve
POST /games/:game_id/scenes/:id/toggle_notification_preference

POST /games/:game_id/scenes/:scene_id/posts      posts#create
GET  /games/:game_id/scenes/:scene_id/posts/:id/edit
PATCH/PUT /games/:game_id/scenes/:scene_id/posts/:id

GET  /games/:game_id/player_management            player_management#show
POST /games/:game_id/player_management/invitations
DELETE /games/:game_id/player_management/invitations/:id
PATCH /games/:game_id/player_management/game_members/:id

GET  /games/:game_id/game_files   game_files#index
POST /games/:game_id/game_files   game_files#create
DELETE /games/:game_id/game_files/:id

GET  /games/:game_id/characters/:id          characters#show
GET  /games/:game_id/characters/:id/versions/:version_id

GET    /profile                   profiles#show
GET    /profile/edit              profiles#edit
PATCH  /profile                   profiles#update
POST   /profile/toggle_hide_ooc

GET  /invitations/:token/accept   invitations#accept

# Dev only
GET /letter_opener  (LetterOpenerWeb — preview emails)
```

---

## Development Workflow

### Cycle

1. Create a testing plan as a markdown file in `tests/integration/`
2. Write failing RSpec tests that describe desired behavior
3. Implement code until tests pass
   - Seek requirements clarification from product owner if unclear
4. Validate changes match requirements
5. Run local dev server and verify in Chrome using the testing plan
6. Confirm all tests pass
7. Run linter

**IMPORTANT: ALL new features must have tests.**

### Running the App Locally

```bash
bin/setup                          # First-time setup
./bin/dev                          # Start web server + Tailwind CSS watcher (Procfile.dev)
# or
bundle exec rails server
```

Email previews available at `/letter_opener` in development.

Component previews available via Lookbook (dev only).

### Running Tests

```bash
bundle exec rspec                            # Full test suite
bundle exec rspec spec/system/               # System tests only
bundle exec rspec spec/models/user_spec.rb   # Single file
```

System tests use the Playwright driver via `capybara-playwright-driver`. Playwright must be installed.

Mobile/responsive tests run at specific viewport sizes (375px, 768px).

### Quality Pipeline

The pre-push hook (`bin/pre-push`) runs the full pipeline:

```bash
bin/rubocop                        # Lint
bin/importmap audit                # JS security
bin/brakeman --no-pager            # Ruby security scan
bundle exec srb tc                 # Sorbet type check
bundle exec rspec                  # Tests + SimpleCov coverage
bundle exec mutant run --usage opensource --since origin/master  # Mutation testing
bin/quality-metrics --check        # Validate against baseline
```

### Quality Gates (enforced by `bin/quality-metrics --check`)

- Line coverage ≥ baseline (max 5% regression)
- Branch coverage ≥ baseline (max 5% regression)
- Sorbet typed file percentage ≥ baseline (max 5% regression)
- Mutation coverage ≥ baseline (max 5% regression)
- Changed `app/` and `lib/` files: line coverage ≥ 80%, branch coverage ≥ 70%
- Changed files must have a Sorbet sigil of `true`, `strict`, or `strong`

---

## Conventions

### Models

- Enums defined with `enum` (Rails 8 style)
- Sorbet type signatures required on all new methods
- Business logic in models or service objects, not controllers

### Controllers

- Thin controllers — delegate logic to models/services
- All actions inside `authenticate :user` block
- Authorization checked in controller (game_master vs player roles)

### Views / Components

- Use ViewComponent (`app/components/`) for reusable UI
- Use Draper presenters (`app/presenters/`) for display-only logic
- ERB templates in `app/views/`
- Markdown rendered via `MarkdownRenderer` service (Redcarpet, HTML sanitized)

### CSS

- **New work:** Use Tailwind utility classes
- **Existing code:** Large vanilla CSS in `app/assets/stylesheets/application.css` — migration in progress
- Do not add new styles to the vanilla CSS file; use Tailwind instead
- Generated CSS goes to `app/assets/builds/` — never edit this directory

### JavaScript

- Stimulus controllers in `app/javascript/controllers/`
- No bundler — ESM via importmap
- Keep JS minimal; prefer Turbo for page updates

### Sorbet

- All new `app/` and `lib/` files need a Sorbet sigil (`# typed: true` minimum)
- Run `bundle exec srb tc` to type-check
- RBI files live in `sorbet/rbi/`; regenerate with `bundle exec tapioca`

### Testing

- **System specs** (`spec/system/`) — full browser tests via Capybara + Playwright
- **Unit specs** — models, services, presenters, components in their respective `spec/` subdirs
- **Factories** in `spec/factories/` — one file per model
- Authentication in specs: use `sign_in_helper.rb` (system) or `request_sign_in_helper.rb` (request specs)
- Transactional fixtures enabled; database cleaned between tests

---

## CI/CD (GitHub Actions)

Defined in `.github/workflows/ci.yml`. Jobs on PR and push to `master`:

| Job | Tool | Notes |
|-----|------|-------|
| `scan_ruby` | Brakeman | Security scan |
| `scan_js` | importmap audit | JS security |
| `lint` | RuboCop | Style enforcement |
| `typecheck` | Sorbet (`srb tc`) | Type correctness |
| `test` | RSpec + SimpleCov + Playwright | Full suite |
| `mutation` | Mutant (`--since origin/master`) | Mutation score |
| `quality_gate` | `bin/quality-metrics --check` | Final quality gate |

---

## Deployment

- **Platform:** Railway.app
- **Container:** Docker (see `Dockerfile`, `railway.toml`)
- **Database:** PostgreSQL (managed by Railway)
- **File storage:** Cloudflare R2 via Active Storage
- **Email inbound:** Mailgun → ActionMailbox
- **Jobs:** Solid Queue (runs in-process via Puma)
- **Cache:** Solid Cache (database-backed)

---

## CLI Tools

- `git` — version control
- `gh` — GitHub PRs and issues (not available in all environments; use MCP GitHub tools if unavailable)
- `rails` — Rails CLI commands
- `bin/pre-push` — Full quality pipeline
- `bin/quality-metrics` — Collect/check quality metrics
