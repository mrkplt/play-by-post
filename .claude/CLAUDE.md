# CLAUDE.md

## Project Overview

Play-by-Post TTRPG — Rails 8 app for asynchronous tabletop RPGs. GMs and players collaborate on scenes through threaded posts, with email notifications and reply-by-email.

- [Product requirements](../context/REQUIREMENTS.md)

**IMPORTANT:** When implementing or modifying any feature, `context/REQUIREMENTS.md` must be updated to reflect the new or changed behaviour before the work is considered complete.

---

## Working With the Owner

The owner has many years of production Rails experience. Treat their direction as
decisions, not opening positions.

- **A directive is not a prompt for alternatives.** Suggesting is fine and wanted —
  say the concern in a sentence or two, then *do what was asked*. Substituting your
  own approach, doing a smaller adjacent thing, or quietly not doing it is not an
  acceptable response to disagreement.
- **If you think they are wrong, research it — do not assert.** Every time that has
  gone badly here, the cause was a confident claim from memory instead of a
  five-minute check:
  - "The database isn't the bottleneck, it's 9%" — measured `sql.active_record`,
    which only counts driver time. `factory_bot.run_factory` showed `create` was
    **43%**. Wrong by ~3×, and it was used to refuse a refactor.
  - "Overriding `save` won't cover `create`/`update`" — a five-line probe showed it
    does. Used to avoid a change that was explicitly requested.
  - "Scopes need real rows or the mutants survive" — a `to_sql` assertion kills the
    same mutants. Never tested before arguing.
  - Proposed `parallel_tests` as the "good choice" — already rejected for timing
    problems, and the evidence was in this file.
- **Bring the measurement, not the opinion.** If a claim would change what gets
  built, it needs a probe, a benchmark, or a diff behind it before it is stated.
- **Re-stating a concern after it has been heard is second-guessing.** Once they
  have responded to a concern, it is settled. Proceed.

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
  pre-push             # Fast local gate — static checks + non-system specs (runs on every push)
  full-check           # Full pipeline on demand — pre-push + system specs + mutation + quality gate
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
5. Push — the pre-push hook runs the fast tier automatically; run `bin/full-check` when you want the heavy tier (system specs, mutation, quality gate) locally instead of waiting on CI

**ALL new features must have tests.**

### Sorbet checklist (every PR)
- Add `# typed: true` sigil to every new or touched file in `app/`, `lib/`, `config/initializers/`
- Declare explicit `sig` on every method called from a ViewComponent template — `SimpleDelegator` passthrough is invisible to Sorbet
- Use `T.must(value)` for nilable associations known to be present at runtime
- Run `bundle exec srb tc` to confirm zero type errors before pushing
- If new RBI files are needed: `bundle exec tapioca`

---

## Quality Pipeline

Two tiers, split by cost:

**Fast tier — `bin/pre-push` (the push hook, ~30s).** Docs-only short-circuit, then static checks and non-system specs:

```bash
bin/docs-only                            # 0. Skip everything on a docs-only diff (mirrors CI's bin/ci-run)
bin/rubocop                              # 1. Lint (Omakase style)          ~3s
bin/check-design-tokens                  # 2. Design-token adherence        <0.1s
bin/check-mutant-coverage                # 3. Mutation registration check   <0.1s
bin/importmap audit                      # 4. JS security                   ~1s
bin/brakeman --no-pager                  # 5. Ruby security                 ~6s
bundle exec srb tc                       # 6. Sorbet type check
SKIP_COVERAGE=1 bundle exec rspec \      # 7. Unit tiers only               ~8s
  --exclude-pattern "spec/system/**/*_spec.rb,spec/requests/**/*_spec.rb"
```

Two things keep step 7 at ~8s (801 examples) instead of ~30s:
- **No browser, no HTTP.** System specs (`spec/system`, ~88s) and request specs (`spec/requests`, ~12s) are excluded — anything issuing an HTTP call belongs in CI, not the commit path. Both still run in `bin/full-check` and CI, which use a bare `bundle exec rspec`.
- **`SKIP_COVERAGE=1`** (honoured in `spec/spec_helper.rb`) turns SimpleCov off, worth ~9s. It's a default, not a removal — `COVERAGE=1 bin/pre-push` forces the report back on, and `bin/full-check`/CI leave both unset so `coverage/` is populated for the gate.

**Use `--exclude-pattern`, not two `--tag` flags.** `--tag ~type:feature --tag ~type:request` looks right and silently fails: both exclusions key on `type`, so the second replaces the first and the browser specs run anyway (1011 examples / 93s instead of 801 / 6.6s).

**Heavy tier — system specs (`type: :feature`, Capybara+Playwright: 210 of 1346 examples but ~85% of suite wall time), mutation testing, and `bin/quality-metrics --check`.** This tier runs in CI (`.github/workflows/ci.yml`) as parallel jobs on every PR and push to `master` — CI is the authoritative gate. To run it locally instead of waiting on CI, use **`bin/full-check`** (fast tier + full rspec + mutation + quality gate; expect several minutes). That's a per-situation choice: hook stays fast on every push, `full-check` when you want the complete verdict before opening a PR or CI turnaround is the bottleneck. In CI, mutation runs after tests (`--jobs 8`) and passes its output to `bin/quality-metrics --record-mutant` before the gate.

### Quality Gates

Enforced by `bin/quality-metrics --check` against `quality_baseline.json`:

| Check | Threshold |
|-------|-----------|
| Global line/branch/sorbet/mutation coverage | ≤ 5% regression from baseline |
| Each changed `app/` or `lib/` file — line coverage | ≥ 80% |
| Each changed `app/` or `lib/` file — branch coverage | ≥ 70% |
| Each changed file — Sorbet sigil | `true`, `strict`, or `strong` |
| View CSS statements (`app/views/*.erb`) | must not increase (push markup into components) |
| ERB logic (ternary / `\|\|` / local-assign, views + component templates) | must not increase (extract to presenter/component method) |

**Two static checks are their own CI jobs** (not part of `quality_gate`), so a failure is identifiable directly from the status list:
- **`design_tokens`** (`bin/check-design-tokens`) — no raw hex in ERB class utilities (`bg-[#…]`); use a `@theme` token. Fails itself on any violation.
- **`mutant_registration`** (`bin/check-mutant-coverage`) — every concrete `app/` class (components, presenters, models, …) must be in `.mutant.yml`. Fails itself if any is missing.

Each is a self-contained executable that owns its pass/fail (`exit 1` on violation). Run locally any time; they don't route through `quality_gate` (which is reserved for evaluating expensive-to-produce coverage/mutation numbers against the baseline).

**Design system:** the UI is component-driven and token-based — see `docs/STYLE_GUIDE.md`. Colours/radii are `@theme` tokens in `app/assets/tailwind/application.css`; browse the component gallery at **`/lookbook`** (dev). Screens compose `Shared::MobileFrameComponent` + a header + `Ui::*`/`Shared::*` components; don't hand-write bespoke screen markup or raw hex.

**Blast radius:** The gate checks every file touched by the branch vs `origin/master`, not just files you intended to change. Any edit to a file that lacks a sigil or has insufficient coverage will fail the gate. Fix both immediately when touching such a file.

**Mutation registration:** Every new component/presenter must be added to `.mutant.yml` under `matcher.subjects` using its exact Ruby constant (e.g. `Shared::PostItemComponent`, `PostPresenter`). The `mutant_registration` CI job fails the build if a `Ui::*`/`Shared::*`/presenter class is missing — no longer just silently unmeasured.

**Updating the baseline:** After an intentional quality improvement run `bin/quality-metrics --save`.

### Quality tooling: field notes

Hard-won specifics for actually clearing the gates. Read this before touching upload/attachment code, controllers, or anything that trips mutation.

**Suite profile — where the time actually goes (measured, 1346 examples):**

| Slice | Examples | Time | Per example |
|-------|----------|------|-------------|
| System (`type: :feature`, Capybara+Playwright) | 210 | ~88s | ~420ms |
| Request specs (full Rails stack, no browser) | 335 | ~14.5s | ~43ms |
| Everything else (models, components, presenters, services, jobs, mailers, helpers) | 801 | ~8.3s | ~10ms |

- **DB-backed factories are the single largest cost, and it grows linearly with the suite.** Instrument `factory_bot.run_factory`, **not** `sql.active_record` — SQL execution time (770ms unit / 1.58s request) badly understates the real cost because it excludes ActiveRecord instantiation, validations, callbacks, and association cascades, all of which `build_stubbed` skips. Measured by strategy: `create` **3184ms of the 7.4s unit tier (43%)** and **5212ms of the 11.9s request tier (44%)** — ~8.4s of the ~19s fast tier. Per call: `create` 1.7–2.8ms, `build` 0.65ms, `build_stubbed` 0.42ms.
- Where the `create` time sits (ms, and share of that directory's runtime): requests 5212 (44%) · models 1018 (53%) · services 961 (53%) · jobs 327 (43%) · components 297 (13%) · mailers 290 (63%) · presenters 183 (37%) · mailboxes 102 · helpers 48.
- **Scopes do not need persisted rows — assert on `to_sql`.** A scope's job is to build the right query; executing it is ActiveRecord's job and is already tested upstream. `expect(Scene.active.to_sql).to include(%q{"scenes"."resolved_at" IS NULL})` needs a connection but zero INSERTs, and kills the same mutants the row-based version did — verified against `-> { all }`, a negation flip, and a wrong-column swap, plus all three `Character.visible_to` branches. For a scope taking collaborators, `instance_double(Game)` + `build_stubbed(:user)` covers the branching. Note SQLite renders booleans as `TRUE`/`FALSE` in `to_sql`, not `1`/`0`.
- **Presenters: stub the association when only a derived value is used.** `ScenePresenter#participant_summary` reads `scene_participants.count`, so `allow(scene).to receive(:scene_participants).and_return(double(count: n))` covers it — no scene, no participants, no cascade. Kills the `count == 1` boundary mutants the row-based version did.
- Still genuinely needs the database: uniqueness validations, FK constraints, callbacks that re-read, and anything asserting what was actually written. `UserPresenter#games_by_recent_activity` is the clearest case — it's a `left_joins`/`group`/`MAX` query ordered by `COALESCE(MAX(scenes.updated_at), games.created_at)`, and whether that fallback ordering is right can only be shown by executing it. Request specs are moot — they're out of the commit path entirely.
- **Expect individual conversions to be invisible.** Removing 6 `create` calls is ~12ms — below run-to-run noise. The payoff is cumulative (1431 creates × ~1.5ms ≈ 2s across the tier) and in the convention new specs land on, not in any single file.
- The factories themselves are already lean (`:user` is an email sequence; `:game` three scalars — no association cascade by default), so the ~2ms is inherent per-`create` ActiveRecord cost. There is no systemic fix; the only lever is not hitting the DB where a spec doesn't need it.
- `SORBET_RUNTIME_DEFAULT_CHECKED_LEVEL=never` shaves ~1.4s but disables runtime type checking that legitimately catches errors in specs — **not** enabled; noted so it isn't rediscovered as free.

**Unit specs run on nulldb; `db: true` opts back into SQLite.**
- `spec/support/nulldb.rb` selects the adapter once per process. `NULLDB=1` runs the mock adapter — ActiveRecord validates, callbacks fire and `to_sql` builds real queries, but nothing is written and queries return empty. Specs needing the real database carry `db: true` and run as a second pass (`--tag db`). `NULLDB=switch` is the diagnostic: it swaps per example so one run covers both populations, at the cost of dropping every model's column cache on each swap. Without `NULLDB` set the tag is inert, so `bin/full-check` and CI are unaffected.
- **806 examples run without a database; 3 keep one**, and only where a write must be read back through machinery that isn't ours: the Active Storage variant key (generated by Active Storage, so a stubbed read would assert our own input), one end-to-end `ExportJob` attach, and one ActionMailbox routing case covering address parsing and the participant gate. Everything else — including query construction, ordering and callback wiring — is asserted without a connection.
- **Patterns that got specs off the database**, in rough order of how often they applied:
  - *Subject runs its own query* → isolate the read behind a named method returning a plain array (`members_for`, `files_for`, `posts_for_prompt`, `games_for`, `expired`), then stub it. This was ~69% of the work.
  - *Branching scope* → extract the decision as a pure function (`Character.visibility_rule` returns a symbol; the scope just applies it). Beats asserting `to_sql` — no quoting, no adapter coupling.
  - *Plain scope* → `where_values_hash`, or `unquoted_sql` from `spec/support/sql_matchers.rb` (quoting is adapter-specific: `"scenes"."id"` on SQLite, `'scenes'.'id'` on nulldb).
  - *Callback* → explicit `save`/`save!` overrides calling the hook, with the body extracted to a pure method (`version_attributes`). Verified: `create`/`update` route through `save`, `create!`/`update!` through `save!`, `touch`/`update_column` bypass both — exactly what `after_save` covered. Wrap `super` in `transaction` to keep rollback semantics.
  - *Association/validation declarations* → `reflect_on_association` and `validators_on` assert the declaration instead of re-testing Rails' machinery.
- **Traps, all hit at least once:** a `sig`-typed param or `T.let` rejects `instance_double` at runtime — use `build_stubbed` or `allow_any_instance_of`. Partial-double verification rejects stubbing `loaded?` on a real Array — use a plain `double`. A symbol (`role: :game_master`) does not cast to the column type under nulldb; pass the string. Never assert on an exact time boundary — assigning a timestamp round-trips through attribute casting, which truncates sub-second precision and flips `>=`; test a second either side, and use `be_within` rather than `eq`. An inner `let(:scene)` that shadows an outer one still runs the outer `let!`, which will try to persist against your stub.

**Approaches already measured and rejected — do not re-propose without new evidence:**
- **Parallel test execution (`parallel_tests`).** Deliberately not in place: it causes timing problems. The symptom is already documented below for `mutant --jobs > 1` — SQLite lock contention surfacing as spurious `BusyException` failures — and the same contention applies to parallel rspec workers. It *looks* attractive (measured 103s → 56s full suite on 4 cores, per-worker DBs via `TEST_ENV_NUMBER`, and a clean run) but **a clean run proves nothing about flakiness**, which is intermittent by definition. It would also need SimpleCov `command_name` + result merging or `quality_gate` reads partial coverage.
- **SQLite pragma tuning** (`synchronous=off`, `journal_mode=memory`): measured 6.64s vs a 6.31s baseline — no gain. Disk I/O is not the cost, so `:memory:` will not help either.
- **`active_mocker`**: last release 2019-09-05, predates Rails 6. Use `activerecord-nulldb-adapter` (above).
- **nulldb as a blanket replacement for `create`**: `create` on nulldb is 0.77ms vs 1.74ms on SQLite, but `build_stubbed` is 0.24ms and needs no adapter. Reach for `build_stubbed` first; nulldb earns its place by letting callbacks and validations run with no connection at all.

**Verify framework behaviour, do not assert it from memory.** Claims about what Rails does internally are cheap to check and easy to get wrong. Overriding `save` was dismissed here on the grounds that `create`/`update` bypass it — a five-line probe (override `save`/`save!`, call each path, print which fired) showed `create` and `update` *do* route through `save`, only the bang variants take `save!`, and `touch`/`update_column` bypass both. Write the probe.

**Ruby gotcha that survived a live bug: `lines << a || b` parses as `(lines << a) || b`.** `<<` binds tighter than `||`, so the fallback is dead code and a blank value pushes `nil`. `GameExportService#readme_content` shipped with this; the coarse zip-based spec never caught it because it always supplied a description. Always parenthesise: `lines << (a.presence || "fallback")`.

**Test DB pollution — the failure mode that looks like broken specs:**
- `use_transactional_fixtures = true` rolls back each example's own writes but does **nothing** about rows already committed to `storage/test.sqlite3`. Several specs (`Scene.active`, `Scene.resolved`, `Character.visible_to`) assert with `contain_exactly` against the whole table, so **any** pre-existing row fails them.
- Two ways this bites: `bin/rails db:prepare` on a *fresh* checkout creates the DB and runs `db:seed` into it (4 spec failures immediately), and any `bin/rails runner` script that creates records in `RAILS_ENV=test` commits them permanently (later runs then fail with `UNIQUE constraint failed: users.email` as factory sequences restart at 1 and collide).
- Fix: `rm -f storage/test.sqlite3* && RAILS_ENV=test bin/rails db:schema:load`. Note `db:schema:load` **fails with a foreign-key error against a populated DB** — delete the file first, don't just reload.
- A clean fast tier is `1136 examples, 0 failures`; `spec/services/attachment_uploader_spec.rb:132` additionally needs ImageMagick installed (CI apt-installs it).

**Running the tools (the sequence that matches CI):**
- Tests + coverage must run *before* `--check`; SimpleCov writes `coverage/`. A **mutation run overwrites nothing useful for line coverage** — if you run `mutant` last, re-run `bundle exec rspec` before `bin/quality-metrics --check` or every changed file reports `0.0%` line coverage (false failure).
- Mutation for CI/gate: `bundle exec mutant run --usage opensource --jobs 4 --since origin/master > tmp/mutant_output.txt 2>&1` then `bin/quality-metrics --record-mutant tmp/mutant_output.txt` then `bin/quality-metrics --check`. CI runs the mutation step with `|| true`, so alive mutants don't fail the build directly — the **`mutation_coverage` floor (currently 83.66) in `--check` is what blocks**.
- The pre-push hook (`.git/hooks/pre-push` → `bin/pre-push`) runs only the fast tier (~30-40s) — mutation and system specs are NOT in the push path. `bin/full-check` is the local command that runs the entire pipeline incl. mutation; it legitimately takes several minutes — run it backgrounded, it is not hung.
- **A failing spec inflates mutation coverage — never read a mutant number from a red suite.** Mutant counts "test failed" as a kill, so a spec that is broken on the real adapter kills every mutation of the subjects it covers. Two broken specs here read as 87.42% when the true number was 75.29%. Always confirm `bundle exec rspec` is green before trusting `--record-mutant`.
- **Extracting a read into a named method and stubbing it everywhere leaves the query unexecuted.** The refactor that moves `game.scenes.includes(...)` into `scenes_for(game)` makes specs fast, but if every caller stubs `scenes_for` then nothing runs the chain and *every* mutation of it survives. Pair each extraction with a direct spec asserting the query it builds (`unquoted_sql`, or argument assertions on a chained double), and keep one spec that drives the caller with the reads stubbed so its loop and guards stay covered.
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

**Test isolation — restore any global you mutate, especially `ActiveJob::Base.queue_adapter`.** The test env runs jobs `:inline`. Several specs flip the adapter to `:test` to inspect enqueued jobs; if one does it **inline in a test body without restoring** (rather than in an `around`/`ensure`), it leaks `:test` into every subsequent spec in the run, so their `deliver_later` mail is enqueued but never performed. This stayed invisible for a long time because the only login mailer used `deliver_now` (adapter-independent) — switching the magic link to `deliver_later` instantly broke 37 downstream feature specs (`sign_in_as` found no delivered email). Lessons: (1) always wrap adapter/config mutation in `around` or `begin/ensure`; (2) a feature-spec sign-in helper should not depend on scraping a delivered email — visit the magic-link **token URL directly** (`Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)` → `user_magic_link_path`), which is delivery- and adapter-independent; (3) tests that assert a `deliver_later` mail was sent must drain/perform jobs or poll `deliveries`, not read it once.

**The gates do NOT run `assets:precompile` — the Docker build does, and it's a different boot context.** Every CI gate (rspec, mutation, sorbet, brakeman) runs in `test`/dev with credentials present. The `build` job runs `SECRET_KEY_BASE_DUMMY=1 rails assets:precompile` in an image with **no master key**, so `Rails.application.credentials` is empty and any config that resolves the R2/S3 service gets a **nil bucket** → `aws-sdk-s3` aborts with `ArgumentError: missing required option :name`. A `config.to_prepare` block that references `ActiveStorage::VariantWithRecord` (or otherwise touches the storage service) runs during precompile and triggers exactly this — passing all gates but breaking master's container build. Guard such boot-time AS/service code with `unless ENV["SECRET_KEY_BASE_DUMMY"]`, and before merging attachment/initializer changes sanity-check locally: `mv config/credentials/production.{key,yml.enc} /tmp/ && SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile` (must exit 0; then move them back).

**Libraries / techniques established:**
- **Time-travel in specs: `Timecop`** (`Timecop.freeze do … end`), in the `:test` group. Do **not** use `ActiveSupport::Testing::TimeHelpers` — it is not mixed in (`freeze_time`/`travel_to` are undefined). Test env uses the `:inline` ActiveJob adapter, so `:purge_later` and other `perform_later` calls run synchronously.
- **Active Storage — prefer public API over patching `Blob`:** `attach`'s documented `key:` argument controls the storage folder/prefix but is only forwarded on the **Hash/io** attachable branch (not `UploadedFile`). To set key + custom metadata uniformly, build the blob with `ActiveStorage::Blob.create_and_upload!(key:, io:, filename:, content_type:, metadata: { custom: {...} })` then `attach(blob)`. `custom_metadata` lives at `blob.metadata[:custom]` and the S3 service maps it to `x-amz-meta-*`. For `VariantWithRecord` thumbnails (no controller in the path), the variant image is attached from a Hash, so merge a `key:` into that Hash via a small `prepend` on `create_or_find_record` — no `Blob#key` override needed. R2 has **no object tagging** and lifecycle rules filter by **prefix + age only**, so custom metadata is for legibility, not automation.

**CI/CD topology — build-verify runs on PRs; publish/deploy is master-only:**
- The **`build`** job builds the linux/arm64 image **on every event including PRs, in parallel with the gates, with `push: false`** — so a broken Dockerfile / `assets:precompile` is caught **before merge**. It publishes nothing.
- The separate **`publish`** job (`needs:` all gates + `build`, `if:` master/tag push) is the only thing that pushes to GHCR and triggers the Coolify deploy, so an image ships only when *everything* is green on master. (Historically these were one master-only `build` job that `SKIPPED` on PRs, which let a precompile break reach master and require a hotfix — hence the split.)
- Still run the local no-credentials precompile check (above) for fast local confidence, but the PR `build` job now catches it in CI too.
- **`master` is squash-merge + delete-branch.** After merge the PR's individual commits are **not** ancestors of `master` (it's a single squash commit), and the source branch ref is **deleted** — pushing another commit to that branch afterward fails with `cannot lock ref … unable to resolve reference`. Land follow-ups on a **fresh branch off the updated `origin/master`** (`git fetch` first); `git diff origin/master..HEAD` will then show only your true delta even after a squash.
- **The pre-push hook runs the fast tier only (~30-40s)** — mutation and system specs moved to CI / `bin/full-check`, so `git push` is no longer minutes-slow. Still let it run to completion uninterrupted — killing it mid-run leaves the ref unpushed (`[remote rejected]`/nothing sent). `--no-verify` is blocked by policy here; don't reach for it. When a push and a background job race, the push captures the ref at push time, so a commit made *after* you start the push won't be included — verify `git ls-remote` vs local HEAD and re-push if you're ahead.

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
