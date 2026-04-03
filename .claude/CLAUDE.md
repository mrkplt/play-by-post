# CLAUDE.md

## Project Overview

Play-by-Post TTRPG — Rails 8 app for asynchronous tabletop RPGs. GMs and players collaborate on scenes through threaded posts, with email notifications and reply-by-email.

- [Product requirements](../context/REQUIREMENTS.md)

**IMPORTANT:** When implementing or modifying any feature, `context/REQUIREMENTS.md` must be updated to reflect the new or changed behaviour before the work is considered complete.

---

## Technology Stack

| Concern | Technology |
|---------|-----------|
| Framework | Rails 8.1 · Ruby 3.3 |
| Database | SQLite (dev/test) · PostgreSQL (prod) |
| Frontend | Hotwire (Turbo + Stimulus) · Importmap (no bundler) · Tailwind CSS |
| UI | ViewComponent · Draper (presenters) · HugeIcons (`icons` gem) |
| Auth | Devise + devise-passwordless (magic link, no passwords) |
| Storage | Active Storage · Cloudflare R2 (prod) · image_processing |
| Jobs | Solid Queue (in-process, no Redis) |
| Cache | Solid Cache (DB-backed) |
| Email out | ActionMailer · Mailgun |
| Email in | ActionMailbox (reply-by-email → posts) |
| Markdown | Redcarpet · Stimulus live preview |
| Pagination | Pagy |
| Types | Sorbet (gradual) · sorbet-runtime |
| Linting | RuboCop (rubocop-rails-omakase) |
| Testing | RSpec · FactoryBot · Capybara · capybara-playwright-driver |
| Coverage | SimpleCov (line + branch) |
| Mutation | mutant-rspec |
| Security | Brakeman · importmap audit |
| Dev tools | Lookbook (component previews) · letter_opener_web |
| Deployment | Railway.app · Docker · Kamal |

---

## Codebase Structure

Standard Rails layout plus these non-standard additions:

```
app/
  components/          # ViewComponent — two namespaces:
    ui/                #   Ui::* — primitive, reusable (Badge, Button, Breadcrumb)
    shared/            #   Shared::* — domain-specific (PostItem, PostComposer, Sidebar, SceneCard)
  presenters/          # Draper — BasePresenter < SimpleDelegator, one per model
    base_presenter.rb
    post_presenter.rb  # (+ game_file, scene, user)

config/
  initializers/
    warden_hooks.rb    # Warden::Manager.after_set_user — updates last_login_at on every auth

sorbet/
  rbi/                 # Generated RBI files (tapioca + shims)
  config/              # sorbet/config

spec/
  requests/            # Request specs — one file per controller
  components/          # ViewComponent specs
  presenters/          # Presenter unit specs
  support/
    sign_in_helper.rb          # system spec auth (Capybara)
    request_sign_in_helper.rb  # request spec auth (Warden)

tests/
  integration/         # Manual testing plans (markdown, not RSpec)

.mutant.yml            # Mutation testing config — all tested classes must be listed here
bin/
  pre-push             # Full local quality pipeline (run before pushing)
  quality-metrics      # Coverage/mutation/typing metric collector and gate checker
```

---

## Domain Model

```
User → GameMember → Game → Scene → Post
                         → GameFile
                         → Character → CharacterVersion
                         → Invitation
User → SceneParticipant → Scene
User → NotificationPreference → Scene
User → UserProfile
Post → PostRead
```

Key model notes:
- `GameMember` role: `game_master` | `player`; status: `active` | `removed` | `banned`
- `Post` — markdown body, editable within 10-min window (`editable_by?`), draft support — see REQUIREMENTS.md
- `UserProfile` — display_name, hide_ooc, last_login_at (updated by Warden hook on every sign-in) — see REQUIREMENTS.md
- `Invitation` — email + token + accepted_at

---

## Routes

Run `rails routes` for the full list. Root → `games#index`. All routes require authentication except `invitations#accept`.

Key named helpers: `game_path`, `game_scene_path`, `game_scene_post_path`, `game_player_management_path`, `game_game_files_path`, `game_character_path`, `profile_path`, `accept_invitation_path`, `user_magic_link_path`.

Dev only: `/letter_opener` (email preview) · Lookbook (component previews).

---

## Development Workflow

1. Write a testing plan in `tests/integration/` (markdown)
2. Write failing RSpec tests
3. Implement until tests pass
4. Verify in browser against the testing plan
5. Run `bin/pre-push` before pushing

**ALL new features must have tests.**

### Sorbet checklist (every PR)
- Add `# typed: true` sigil to every new or touched file in `app/`, `lib/`, `config/initializers/`
- Declare explicit `sig` on every method called from a ViewComponent template — `SimpleDelegator` passthrough is invisible to Sorbet
- Use `T.must(value)` for nilable associations known to be present at runtime
- Run `bundle exec srb tc` to confirm zero type errors before pushing
- If new RBI files are needed: `bundle exec tapioca`

---

## Quality Pipeline

`bin/pre-push` runs the full pipeline and is the gate before every push:

```bash
bin/rubocop                              # 1. Lint (Omakase style)
bin/importmap audit                      # 2. JS security
bin/brakeman --no-pager                  # 3. Ruby security
bundle exec srb tc                       # 4. Sorbet type check
bundle exec rspec                        # 5. Tests + SimpleCov coverage
bundle exec mutant run --usage opensource --since origin/master  # 6. Mutation
bin/quality-metrics --check              # 7. Gate — fails build if metrics regress
```

The same pipeline runs in CI (`.github/workflows/ci.yml`) on every PR and push to `master`, as parallel jobs. Mutation runs after tests (`--jobs 8`) and passes its output to `bin/quality-metrics --record-mutant` before the gate.

### Quality Gates

Enforced by `bin/quality-metrics --check` against `quality_baseline.json`:

| Check | Threshold |
|-------|-----------|
| Global line/branch/sorbet/mutation coverage | ≤ 5% regression from baseline |
| Each changed `app/` or `lib/` file — line coverage | ≥ 80% |
| Each changed `app/` or `lib/` file — branch coverage | ≥ 70% |
| Each changed file — Sorbet sigil | `true`, `strict`, or `strong` |

**Blast radius:** The gate checks every file touched by the branch vs `origin/master`, not just files you intended to change. Any edit to a file that lacks a sigil or has insufficient coverage will fail the gate. Fix both immediately when touching such a file.

**Mutation registration:** Every new class must be added to `.mutant.yml` under `matcher.subjects` using its exact Ruby constant (e.g. `Shared::PostItemComponent`, `PostPresenter`, `PostRead`). Omitted classes are silently unmeasured.

**Updating the baseline:** After an intentional quality improvement run `bin/quality-metrics --save`.

---

## Conventions

### Controllers
- Thin — delegate logic to models/services
- Sorbet sigil required; per-action `sig` blocks not needed

### Presenters & ViewComponents
- `BasePresenter < SimpleDelegator` — silently exposes all model methods, but **Sorbet cannot see them**. Every method a ViewComponent template calls on a presenter must be explicitly declared on the presenter with a Sorbet `sig`. Do not rely on `SimpleDelegator` passthrough.
- Happy path and error path in the same controller action must render the same component. Never mix a ViewComponent in one branch and a partial in the other. Delete old partials once fully replaced.
- Component namespaces: `Ui::*` for primitives, `Shared::*` for domain components.

### CSS
- New work: Tailwind only. Do not add to `app/assets/stylesheets/application.css` (legacy, migration in progress).
- Never edit `app/assets/builds/` (generated).

### Sorbet
- `# typed: true` minimum on all new/touched files in `app/`, `lib/`, and `config/initializers/`
- Controllers need the sigil; per-action `sig` blocks not required
- Use `T.must(value)` for nilable associations known to be present at runtime
- Regenerate RBIs: `bundle exec tapioca`

### Testing
- Request specs: `spec/requests/`, one file per controller
- Auth in request specs: `sign_in(user)` — bypasses all controller code, goes directly through Warden
- Magic link flow in specs: `Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)` → `GET user_magic_link_path, params: { user: { email: user.email, token: token } }`
- Cross-authentication callbacks (e.g. updating `last_login_at`) belong in `config/initializers/warden_hooks.rb` via `Warden::Manager.after_set_user` — not in `Users::SessionsController`, which is not in the call path for magic link sign-ins.
