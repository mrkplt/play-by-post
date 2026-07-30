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
| Database | SQLite everywhere · prod runs from a mounted volume |
| Frontend | Hotwire (Turbo + Stimulus) · Importmap (no bundler) · Tailwind CSS |
| UI | ViewComponent · Draper (presenters) · HugeIcons (`icons` gem) |
| Auth | Devise + devise-passwordless (magic link, no passwords) |
| Storage | Active Storage · Cloudflare R2 (prod) · image_processing |
| Jobs | Solid Queue (in-process, no Redis) |
| Cache | Solid Cache (DB-backed) |
| Email out | ActionMailer · Resend (`resend` gem) |
| Email in | ActionMailbox · Resend inbound webhook (custom ingress, Svix-signed) |
| Markdown | Redcarpet · Stimulus live preview |
| Pagination | Pagy |
| Types | Sorbet (gradual) · sorbet-runtime |
| Linting | RuboCop (rubocop-rails-omakase) |
| Testing | RSpec · FactoryBot · Capybara · capybara-playwright-driver |
| Coverage | SimpleCov (line + branch) |
| Mutation | mutant-rspec |
| Security | Brakeman · importmap audit |
| Dev tools | Lookbook (component previews) · letter_opener_web |
| Deployment | Coolify (self-hosted) · Docker image built in GitHub Actions, pulled from GHCR |
| Email / LLM / Storage | Resend · OpenRouter · Cloudflare R2 |
| Configuration | `docs/CONFIGURATION.md` is the source of truth for all env vars and credentials |

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

### Quality tooling: field notes

Hard-won specifics for actually clearing the gates. Read this before touching upload/attachment code, controllers, or anything that trips mutation.

**Running the tools (the sequence that matches CI):**
- Tests + coverage must run *before* `--check`; SimpleCov writes `coverage/`. A **mutation run overwrites nothing useful for line coverage** — if you run `mutant` last, re-run `bundle exec rspec` before `bin/quality-metrics --check` or every changed file reports `0.0%` line coverage (false failure).
- Mutation for CI/gate: `bundle exec mutant run --usage opensource --jobs 4 --since origin/master > tmp/mutant_output.txt 2>&1` then `bin/quality-metrics --record-mutant tmp/mutant_output.txt` then `bin/quality-metrics --check`. CI runs the mutation step with `|| true`, so alive mutants don't fail the build directly — the **`mutation_coverage` floor (currently 83.66) in `--check` is what blocks**.
- The pre-push hook (`.git/hooks/pre-push` → `bin/pre-push`) runs the *entire* pipeline incl. mutation, so `git push` legitimately takes several minutes. Run it backgrounded; it is not hung.
- `mutant` runs with `--jobs > 1` against SQLite can emit spurious `SQLite3::BusyException: database is locked` "neutral" failures. Re-run single-job (`--jobs 1 <Subject>`) to confirm a mutant is genuinely alive before chasing it.

**ERB gate (bites every view edit):**
- Inline Tailwind in a `.erb` **fails** the CSS-statements check. Move markup into a `Shared::*`/`Ui::*` ViewComponent (CSS is allowed/tracked there). RuboCop does not lint `.erb`, so `bin/rubocop <file.erb>` reports false syntax "offenses" — ignore; the real gate is `bin/quality-metrics`.
- `||` fallbacks, ternaries, and local assigns in ERB **output tags** fail the ERB-logic check. Extract to a presenter/component Ruby method (e.g. `error_message` returning `a || b`).

**Mutation blast radius (a feature, not a trap):**
- `--since origin/master` pulls **every mutation of every subject in a file you touched** into scope — including pre-existing gaps. Adding a one-line method to `PostsController`/`ScenesController` surfaced their legacy coverage (74% / 65%) and it counted against the aggregate. **This is good:** it exposes untested code exactly when you are in a position to test it, and every file dragged in makes the whole system more reliable. Make the edit the task needs and **write tests to lift the whole subject above the floor** — do not shy away from a necessary change, minimize touched files to duck the gate, or contort the code to keep a file out of scope. Lifting those two controllers to 92% / 95% was the point, not a cost. **Always add a new class to `.mutant.yml` first** or it is silently unmeasured.

**Killing mutants with tests — patterns that worked here:**
- *Read the `evil:` diff* in the mutant output to see the exact mutation; that tells you what assertion is missing.
- **Comparison / boundary** (`..` vs `...`, `<=` vs `<`): add a test at the *exact* cutoff. E.g. a record at `7.days.ago` must be deleted (kills `...`), one at `7.days.ago + 1.second` must survive.
- **Delegation with derived args** (a job/controller calling `Service.attach(kind:, user:, …)`): `allow(Service).to receive(:attach)` then `expect(...).to have_received(:attach).with(hash_including(...))` or a block asserting specific keys. Kills argument-construction mutants *and* dodges the Sorbet-double problem below.
- **`.compact` / nil-omission:** assert both that a provided optional key is present *and* `contain_exactly(...)` for the all-nil case.
- **String vs Time:** ActiveSupport's `Time#==` coerces strings, so `expect(x).to eq("…Z")` does **not** catch a dropped `.iso8601`. Assert the class too: `be_a(String).and eq("…Z")`.
- **Redundancy is a real finding:** a `nil`-replacement mutant surviving a whole line often means the line is redundant. Here `request.archive.purge if attached?` was redundant because `has_one_attached` defaults to `dependent: :purge_later` — deleting the line (relying on `destroy`) both simplified the code and killed the mutant.
- **Equivalent mutants** (`Time.current.utc` when app TZ is already UTC; `is_a?(Hash)` vs `instance_of?(Hash)`; stripping a pure `T.must` Sorbet assertion) cannot be killed without contrived input. Leave them if the aggregate stays above floor; this codebase kills via tests rather than `# mutant:disable`, so only disable as a last resort with justification.

**Sorbet + sorbet-runtime + specs:**
- `sig`-typed methods **reject RSpec doubles at runtime** (`TypeError: expected X got RSpec::Mocks::Double`). Type params that receive mocks (attachments, services) as `T.untyped`, or stub at the collaborator boundary.
- New gem ⇒ `bundle exec tapioca gem <name>` for its RBI (Timecop needed this). **Tapioca may also delete unrelated RBIs** as it reconciles the gem set — `git checkout --` those back and keep only the intended new RBI.
- `config/initializers/*` doing metaprogramming (`prepend`, `class_eval`) are `# typed: false` and are **not** gate-checked for sigil/coverage — the safe home for framework patches.

**The gates do NOT run `assets:precompile` — the Docker build does, and it's a different boot context.** Every CI gate (rspec, mutation, sorbet, brakeman) runs in `test`/dev with credentials present. The `build` job runs `SECRET_KEY_BASE_DUMMY=1 rails assets:precompile` in an image with **no master key**, so `Rails.application.credentials` is empty and any config that resolves the R2/S3 service gets a **nil bucket** → `aws-sdk-s3` aborts with `ArgumentError: missing required option :name`. A `config.to_prepare` block that references `ActiveStorage::VariantWithRecord` (or otherwise touches the storage service) runs during precompile and triggers exactly this — passing all gates but breaking master's container build. Guard such boot-time AS/service code with `unless ENV["SECRET_KEY_BASE_DUMMY"]`, and before merging attachment/initializer changes sanity-check locally: `mv config/credentials/production.{key,yml.enc} /tmp/ && SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile` (must exit 0; then move them back).

**Libraries / techniques established:**
- **Time-travel in specs: `Timecop`** (`Timecop.freeze do … end`), in the `:test` group. Do **not** use `ActiveSupport::Testing::TimeHelpers` — it is not mixed in (`freeze_time`/`travel_to` are undefined). Test env uses the `:inline` ActiveJob adapter, so `:purge_later` and other `perform_later` calls run synchronously.
- **Active Storage — prefer public API over patching `Blob`:** `attach`'s documented `key:` argument controls the storage folder/prefix but is only forwarded on the **Hash/io** attachable branch (not `UploadedFile`). To set key + custom metadata uniformly, build the blob with `ActiveStorage::Blob.create_and_upload!(key:, io:, filename:, content_type:, metadata: { custom: {...} })` then `attach(blob)`. `custom_metadata` lives at `blob.metadata[:custom]` and the S3 service maps it to `x-amz-meta-*`. For `VariantWithRecord` thumbnails (no controller in the path), the variant image is attached from a Hash, so merge a `key:` into that Hash via a small `prepend` on `create_or_find_record` — no `Blob#key` override needed. R2 has **no object tagging** and lifecycle rules filter by **prefix + age only**, so custom metadata is for legibility, not automation.

**CI/CD topology — build-verify runs on PRs; publish/deploy is master-only:**
- The **`build`** job builds the linux/arm64 image **on every event including PRs, in parallel with the gates, with `push: false`** — so a broken Dockerfile / `assets:precompile` is caught **before merge**. It publishes nothing.
- The separate **`publish`** job (`needs:` all gates + `build`, `if:` master/tag push) is the only thing that pushes to GHCR and triggers the Coolify deploy, so an image ships only when *everything* is green on master. (Historically these were one master-only `build` job that `SKIPPED` on PRs, which let a precompile break reach master and require a hotfix — hence the split.)
- Still run the local no-credentials precompile check (above) for fast local confidence, but the PR `build` job now catches it in CI too.
- **`master` is squash-merge + delete-branch.** After merge the PR's individual commits are **not** ancestors of `master` (it's a single squash commit), and the source branch ref is **deleted** — pushing another commit to that branch afterward fails with `cannot lock ref … unable to resolve reference`. Land follow-ups on a **fresh branch off the updated `origin/master`** (`git fetch` first); `git diff origin/master..HEAD` will then show only your true delta even after a squash.
- **The pre-push hook runs the entire pipeline including ~3-4 min of mutation**, so `git push` is genuinely slow. Let it run to completion uninterrupted — killing it mid-mutation leaves the ref unpushed (`[remote rejected]`/nothing sent). `--no-verify` is blocked by policy here; don't reach for it. When a push and a background job race, the push captures the ref at push time, so a commit made *after* you start the push won't be included — verify `git ls-remote` vs local HEAD and re-push if you're ahead.

---

## Conventions

### Controllers
- Thin — delegate logic to models/services
- Sorbet sigil required; per-action `sig` blocks not needed

### Presenters & ViewComponents

**Role split — enforce strictly:**
- **Presenters hold presentation logic:** data transformation, display-ready strings, CSS class selection based on model state, formatted timestamps, derived boolean flags for rendering decisions.
- **ViewComponents hold visual presentation:** HTML structure, which sub-components to render, slot content. A component's Ruby class may compute CSS class strings that are purely additive (e.g. combining a BASE constant with a variant), but must not inspect model state or branch on domain data.

**ERB template rules — no logic in templates:**
- No ternaries in output tags: `<%= a ? b : c %>` → extract a method
- No Boolean-OR fallbacks in output tags: `<%= a || b %>` → extract a method
- No inline conditionals on HTML attributes: `<div <% if x %> data-foo="bar"<% end %>>` → extract a method that returns the attribute hash

**Sorbet:**
- `BasePresenter < SimpleDelegator` silently exposes all model methods, but **Sorbet cannot see them**. Every method a ViewComponent template calls on a presenter must be explicitly declared on the presenter with a Sorbet `sig`. Do not rely on `SimpleDelegator` passthrough.

**Other rules:**
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
