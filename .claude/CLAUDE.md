# CLAUDE.md

## Project Overview

Play-by-Post TTRPG — Rails 8 app for asynchronous tabletop RPGs. GMs and players collaborate on scenes through threaded posts, with email notifications and reply-by-email.

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

### Planning and decisions

- **Decide on evidence now; do not defer a decision into a spike.** "We are writing a
  plan, not a plan for a plan contingent on a plan." A gating "Phase 1 spike: investigate
  X, then re-target everything" is almost always a decision dodged. If X can be answered by
  research (docs, a grep, a measurement), answer it and write the decision in — with the
  rationale that settled it. Example this earned: the media-templates-vs-CSS question was
  headed for a gating spike; researching it (Turbo restoration-visit caching is unfixable
  for UA variants; the "contortions" being deleted were ~3 CSS rules) decided it outright
  (keep CSS), and the spike vanished.
- **Finish the work in scope — do not spin cleanup into new cards.** "Not finishing the
  work originally is how we got here." The 25 unstandardized `button_to` sites and the
  stale `Ui::ButtonComponent` existed *because* earlier cleanup was deferred to tickets that
  never happened. Consolidation a task touches (adopting an existing primitive, deleting
  dead code, deduping) is part of that task, not a follow-up. (Mirrors the gem-maintenance
  rule: normal maintenance, in scope.)
- **Subagents report facts; keep/drop and prioritization are the owner's.** A survey agent
  called four extractions "low value" — from line-count, not measurement — and was wrong:
  it missed that a badge cluster recurred across four files and that buttons bypassed an
  existing primitive. Have agents surface locations, counts, coupling, gate-exposure; make
  the value judgment yourself, and never let an agent's "not worth it" pre-filter what the
  owner sees.
- **Verify agent claims against the code before trusting them.** Review agents in this repo
  hallucinated a "5 existing callers" count (there were zero) and a phantom line-number
  drift (the numbers were correct). A 10-second grep caught each. Cross-check any
  load-bearing claim — especially file:line references and "X already exists" — before it
  drives work.
- **A plan handed to an implementer is a spec, not a negotiation history.** Strip the
  discarded options, the "why we chose this," the review-round attributions. Put file:line
  references *inline at the instruction that needs them*, not in an addendum.

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
- `Game` deletion is two-phase: soft delete (`deleted_at`, hidden by a `default_scope`) then a scheduled purge. **The purge does NOT use `dependent:` cascades** — `GamePurgeJob` collects and deletes a game's records and Active Storage artifacts explicitly, child-first. **Adding any association under a game, or any attachment to a record below a game, means `GamePurgeJob` (`#delete_records` / `#purge_artifacts`) MUST be updated too**, or those rows/blobs are orphaned on purge. The end-to-end spec in `spec/jobs/game_purge_job_spec.rb` is the guardrail — populate the new record/attachment there so a missed table fails the suite. See REQUIREMENTS "Game Deletion".

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

### Gem Maintenance

The `pre-push` hook and CI enforce two outdated-gem thresholds — this is normal
maintenance, not out of scope for any task:

- **Updatable > 5:** "There are too many out of date gems in this project, you
  need to bundle update and add it to the commit. This is normal maintenance, and
  is within scope of the task." Fix: `bundle update` (no arguments), commit the
  lockfile.
- **Pinned > 8:** "One or many gems are very out of date. You need to tell the
  user you can not push, you need direction on what to do next. You are at an
  impasse." For each pinned gem, check whether its blocker has a newer release
  that relaxes the constraint. Update blockers where possible; document the rest
  in `context/GEM_PINNED.md` with the gem name, current constraint, blocker, and
  why it matters.

Both gates block the push and CI. Do not skip or lower the thresholds — the
point is to surface drift early so it stays manageable.

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
- **Reproduce CI's *environment*, not just its commands.** The test env must behave identically in both places, so `config/environments/test.rb` sets `config.eager_load = true` **unconditionally** — deliberately not the Rails default of `ENV["CI"].present?`, which lazy-loads locally and eager-loads on CI. Do not "restore" the conditional: that split cost a full debugging cycle. Under eager loading ViewComponent compiles a **templateless** component (one rendering from `def call`, no sibling `.html.erb`) by *copying* `call` into a generated `_call_<name>` at boot, and `render_template_for` dispatches to the copy — so mutant's per-mutation rewrite of `call` never runs and every mutation of it, plus every private method reachable only from it, survives. `Ui::TurnstileWidgetComponent` measured **98.33% locally and 60.0% on CI** (floor 80) from this alone, with a green suite both times. `spec/support/view_component.rb` recompiles inline-call components before each example so the copy tracks the live method. The tell for this class of bug: a mutant that replaces an entire method body with `raise` survives — that method is never being invoked. Eager loading also catches a file no spec references failing to load, which lazy loading reports as green; measured cost is ~0.4s on a single-file run and nil on the full tier.
- **Check `ruby -v` before trusting a local gate run.** `.ruby-version` pins 3.3.6 and the vendored gems are built for it, but Homebrew ruby (4.0.2) sits earlier on PATH in a normal shell — and `bin/full-check` used to force it on explicitly. Both scripts now bootstrap rbenv the way the git hook does. A number produced on the wrong interpreter is not evidence about CI.
- Tests + coverage must run *before* `--check`; SimpleCov writes `coverage/`. A **mutation run overwrites nothing useful for line coverage** — if you run `mutant` last, re-run `bundle exec rspec` before `bin/quality-metrics --check` or every changed file reports `0.0%` line coverage (false failure).
- Mutation for CI/gate: `bundle exec mutant run --usage opensource --jobs 4 --since origin/master > tmp/mutant_output.txt 2>&1` then `bin/quality-metrics --record-mutant tmp/mutant_output.txt` then `bin/quality-metrics --check`. CI runs the mutation step with `|| true`, so alive mutants don't fail the build directly — the **`mutation_coverage` floor (currently 83.66) in `--check` is what blocks**.
- The pre-push hook (`.git/hooks/pre-push` → `bin/pre-push`) runs only the fast tier (~30-40s) — mutation and system specs are NOT in the push path. `bin/full-check` is the local command that runs the entire pipeline incl. mutation; it legitimately takes several minutes — run it backgrounded, it is not hung.
- **A failing spec inflates mutation coverage — never read a mutant number from a red suite.** Mutant counts "test failed" as a kill, so a spec that is broken on the real adapter kills every mutation of the subjects it covers. Two broken specs here read as 87.42% when the true number was 75.29%. Always confirm `bundle exec rspec` is green before trusting `--record-mutant`.
- **Extracting a read into a named method and stubbing it everywhere leaves the query unexecuted.** The refactor that moves `game.scenes.includes(...)` into `scenes_for(game)` makes specs fast, but if every caller stubs `scenes_for` then nothing runs the chain and *every* mutation of it survives. Pair each extraction with a direct spec asserting the query it builds (`unquoted_sql`, or argument assertions on a chained double), and keep one spec that drives the caller with the reads stubbed so its loop and guards stay covered.
- `mutant` runs with `--jobs > 1` against SQLite can emit spurious `SQLite3::BusyException: database is locked` "neutral" failures. Re-run single-job (`--jobs 1 <Subject>`) to confirm a mutant is genuinely alive before chasing it.

**ERB gate (bites every view edit):**
- Inline Tailwind in a `.erb` **fails** the CSS-statements check. Move markup into a `Shared::*`/`Ui::*` ViewComponent (CSS is allowed/tracked there). RuboCop **does** now lint `.erb` (via `rubocop-erb` + the `herb` parser, enabled through `plugins:` in `.rubocop.yml`): `bin/rubocop` inspects the Ruby inside every `app/**/*.erb` and its offenses are real. That is distinct from the architectural ERB-logic gate in `bin/quality-metrics` (no ternary/`||`/control-flow in output tags) — rubocop-erb styles the Ruby that legitimately remains. **No inline `# rubocop:disable`** — fix the code (a render complex enough to tempt a disable is a view-model extraction candidate) or, as a last resort, remove/scope the rule in config.
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
- **Presenters hold data transformation:** mutating model data into presentation-ready shape — formatted timestamps, display-ready strings, derived boolean flags, computed display values. Presenters do NOT handle CSS class selection or visual concerns.
- **ViewComponents hold visual presentation:** HTML structure, CSS class selection based on model state, which sub-components to render, slot content. A component's Ruby class may compute CSS class strings that are purely additive (e.g. combining a BASE constant with a variant).

**When implementing or updating a ViewComponent:**
- Always introduce new ViewComponents instead of raw HTML — never hand-write bespoke screen markup
- Survey the codebase for similar implementations in HTML and refactor them into the component
- Variations on a theme should be parameterized (size variants, accent options, etc.) rather than creating separate components
- **Gold standard patterns:** `Ui::IconComponent` (domain-specific mapping with size/accent parameters) and `Ui::MarkdownRenderComponent` (configurable rendering)
- New components must be registered in `.mutant.yml` and have full test coverage

**Component structure:**
- Ruby class + ERB template pair in `app/components/{namespace}/{name}_component.rb` and `.html.erb`
- Namespace by purpose: `Ui::*` for primitives (reusable across apps), `Shared::*` for domain-specific (project-specific)
- Type annotations: `# typed: strict` on all component Ruby files

**Variants & parameters:**
- Parameterize variations rather than creating separate components (e.g., `Ui::IconComponent` handles size/accent)
- Use constants for fixed options (like `SIZES`, `ICON_MAP` in the Icon component)
- Provide sensible defaults so callers only specify what differs

**Composition patterns:**
- Use `renders_one` / `renders_many` for complex component composition (slots)
- Use `content` for simple HTML wrapping
- Extract reusable pieces as separate components rather than duplicating

**Testing components:**
- Component specs in `spec/components/{namespace}/`
- Test all variants — iterate over constants like `SIZES.each_key` to ensure all combinations render
- Use `render_inline` for assertions (not `render_component`)
- Mock external dependencies — use `instance_double` for services/models

**CSS handling:**
- Tailwind only — no inline styles, no separate CSS files for new components
- Compose classes from constants and parameters (like `BASE + variant`)
- No raw hex — use design tokens from `@theme`

**Documentation:**
- Add Lookbook previews in `app/components/{namespace}/{name}_component_preview.rb`
- Browse component gallery at `/lookbook` in dev

**Migration patterns:**
- Extract from views when HTML patterns repeat — replace partials, delete old partials once fully replaced
- Refactor incrementally — don't rewrite entire views at once; extract one component at a time

**ERB template rules — no logic in templates:**
- No ternaries in output tags: `<%= a ? b : c %>` → extract a method
- No Boolean-OR fallbacks in output tags: `<%= a || b %>` → extract a method
- No inline conditionals on HTML attributes: `<div <% if x %> data-foo="bar"<% end %>>` → extract a method that returns the attribute hash

**Sorbet:**
- `BasePresenter < SimpleDelegator` silently exposes all model methods, but **Sorbet cannot see them**. Every method a ViewComponent template calls on a presenter must be explicitly declared on the presenter with a Sorbet `sig`. Do not rely on `SimpleDelegator` passthrough.

**Other rules:**
- Happy path and error path in the same controller action must render the same component. Never mix a ViewComponent in one branch and a partial in the other. Delete old partials once fully replaced.
- Component namespaces: `Ui::*` for primitives, `Shared::*` for domain components.

**Components own their content — they are not thin HTML wrappers.** A "status badge row" or a "labeled control row" component holds its labels/controls/conditions and *is* the pattern; wrapping an already-shared primitive (e.g. nesting two `Ui::BadgeComponent` renders inside conditionals) only to add a container is not extraction. But a component takes **derived, presentation-ready data, never a raw model**: `Shared::StatusBadgeRowComponent` takes a pre-computed `[{label:, variant:}]` array (a presenter picks the symbolic `variant:` from `Ui::BadgeComponent`'s palette) — it does not receive a `Scene`/`Character` and compute `.private?`/`.resolved?` itself. That would violate the presenter/component split and force a `T.any(...)` sig across model shapes.

That array's shape is declared as `Badge = T.type_alias { { label: String, variant: Symbol } }` — **a named interface for data, not a class**. Note the two things both called "badge" and keep them straight: `Ui::BadgeComponent` is the *component* that renders one badge; `Badge` is the *shape* of the data describing one before it becomes a component. The presenter says "Private, yellow" (display logic); the row component decides that means a `Ui::BadgeComponent` (markup). Keeping construction in the component is why a change to how badges render is one edit rather than one per presenter.

**`bin/check-view-layering` is the enforced statement of these rules** — it fails on a model reaching a view ivar, a presenter or component, and its output explains the whole layering contract. Read the gate rather than restating its rules here; the two drift otherwise. Two things it encodes that are easy to get wrong from memory: classification is by **inheritance, not name** (a `FooPresenter` that does not inherit `BasePresenter` is not a presenter), and a **hash is opaque** — the gate permits hashes without inspecting them, because the hash is where irregular front-end reality is allowed to live. Arrays, tuples and type aliases *are* resolved through to their contents, which is why `Badge` (a hash) passes and a tuple holding `T::Array[Character]` does not.

### Policies & authorization

**Every policy question is one of three distinct things, and they must not collapse into each other:**
- **System function** — Pundit/ActiveRecord vocabulary (`update?`, `destroy?`, `show?`) meaning "this row may be modified/deleted/viewed." Exists because `authorize`/`policy_scope` infer the method name from `action_name`.
- **Role** — a domain fact about a person (`gm?`, `owner?`, `write_member?`): who they are, not what they're allowed to do.
- **Game function (capability)** — what is actually being decided: "may this user manage this game's pages," "may this user resolve this scene." This is the stable concept; who satisfies it is not.

**Domain understanding this encodes:** a GM is currently the same person as the game owner, but that will not always be true — a game owner may not be a GM, a game may have many GMs or none, and GM-only functions may later granularize to permission levels or specific players. Writing the capability *as* the role (`policy(@game).update?` meaning "is this user the GM") bakes `owner == GM == can-do-everything` into every call site, so the rule can never change in one place.

**The rule:**
- **Capability predicates are the public surface.** Controllers, views, components, and presenters ask only capability questions, named for the game function (`manage?`, `resolve?`, `manage_participants?`, `participate?`, `assign_owner?`) — never a role question and never a bare CRUD predicate borrowed for a different purpose.
- **Role predicates stay `private`** inside the policy. They are the *implementation* of a capability — the one line that changes when a rule granularizes.
- **`update?`/`destroy?`/`show?` remain**, because Pundit infers them from `action_name`, but their bodies must delegate to a capability predicate, not duplicate the role check.
- **`policy(x).update?` (or `.show?`) must never be used as a stand-in for "is GM" (or "can view").** If a call site is asking a capability question, it calls a capability predicate — `GamePolicy#manage?` / `#view?`, not `#update?` / `#show?` reused out of convenience.
- **Do not add a public role-named method anywhere** (e.g. a public `GamePolicy#game_master?`) — that's the same mistake one level down: a role back on the public surface.

This extends to the view layer: a component parameter or presenter method is a public API too, so it is named for the capability (`can_manage:`, `GamePresenter#can_manage?`), never the role. A predicate answering an authorization question must ask the policy — `Shared::SidebarComponent` once read `member_for(user).game_master?` directly, which looks converted once its call site is renamed but silently diverges from every other check the day the rule granularizes.

**The completion test: `gm?` must have exactly one caller — the capability.** If it appears in three CRUD bodies, granularizing means editing three lines, which is the thing this convention exists to prevent. Every policy satisfies this except `CharacterPolicy`, where `assign_owner?` and `manage_roster?` are deliberately distinct game functions that happen to share a rule today.

**Copy `GamePolicy#manage?`/`#view?` or `NotebookEntryPolicy#manage?`** — both implement the rule end to end: CRUD predicates delegate, role predicates are private.

**When converting a call site, convert the controller and its views together.** A view gated on `can_manage?` whose controller still loads the data under `update?` is identical today and raises `NoMethodError` on nil the day they diverge — a split-brain that is harder to spot than the original conflation.

### Navigation architecture (target shell)

The app has **two-tier navigation**, and the fix for "varying presentation" is that *one* header renders on every screen (varying markup per screen is the bug, not the goal):
- **Tier 1 (site-wide):** the hamburger opens the global nav drawer (`Shared::NavDrawerComponent`, always in the DOM via `application.html.erb`). The drawer only *opens* if a hamburger button (`data-action="click->sidebar#open"`) is on the page — so every header must render one. A back-arrow-only header is a nav dead-end.
- **Tier 2 (in-game):** the pill tabs (`Ui::PillTabsComponent`, `:switch` = client-side panels on `games/show`, `:link` = cross-page).

**The universal-header pattern:** one `Header` component on every screen, exposing a **generic `secondary_nav:` slot** (plus nilable `gear:`/`breadcrumbs:`). A screen passes the section's menu into the slot — `GameNav` for game sections, nothing for a plain page, another section's menu later — with no change to `Header`. "Which menu" is a passed-in component, never a hand-rolled per-screen layout. This is the standardization mechanism; reuse the `renders_one` slot idiom already in `Shared::MobileFrameComponent` (header/footer slots — the footer is where a page's action buttons belong, not mid-body).

Responsive is **CSS `@media` at 1024px**, not template variants (evaluated and rejected: UA gives device-class not viewport-width, and Turbo restoration visits serve a cached variant with no re-negotiation). The live conditional-nav CSS is only ~3 rules; don't mistake it for complexity worth a variant split.

### Forms & text fields

- **Every user-editable multi-line text field is a markdown field.** If a person can type multi-line prose into it, it must render markdown on display **and** carry the standard editing affordances: the `Shared::MarkdownToolbarComponent` toolbar directly above the textarea, plus a live `markdown-base` preview below it (wire the form with `data: { controller: "markdown-preview markdown-toolbar" }` and the textarea with the `markdown-preview`/`markdown-toolbar` targets + `input->markdown-preview#update`). Render the stored value through `MarkdownRenderer` wherever it is shown. There is no "plain textarea for prose" — do not add one. Copy the wiring from `Shared::PageFormComponent` / `Shared::GameFormComponent`.
- **Single-line identifier inputs are the only exception** (e.g. game name, scene title): short labels, not prose — no toolbar, no markdown.
- **Campaign Notebook entries are the one deliberate no-preview field.** They keep the toolbar and render markdown once promoted, but the edit screen is a large writing surface with no live preview: entries are GM scratchpad, not published content, so presentation waits until the entry becomes a Page. Do not "fix" this back.
- Every prose field is migrated: post composer/edit, character sheets, scene summaries, game description, scene resolution/outcome, and the feedback modal body. There is no remaining plain-textarea prose field — keep it that way.

**The markdown editor is composed of regions, not toggled by flags.** `Ui::MarkdownEditorComponent::Config` carries a `regions:` collection (`ToolbarRegion`, `PreviewRegion`); each region reports where it sits and which component fills it, and the editor enumerates rather than branching. Turning a region off means omitting it — there is no `toolbar:`/`preview:` boolean. `Config.with_preview(preview_class:)` builds the usual toolbar-plus-preview surface most callers want. Heights are steps on `Config::HEIGHTS` (`sm` 20vh / `md` 30vh / `lg` 40vh / `xl` 60vh), never raw px; `HEIGHTS.fetch` raises on anything off-scale. `rows:` is an editor parameter, not layout config.

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

### Responsive / viewport testing (system specs)

The layout is responsive with a **single desktop breakpoint at 1024px** (media query in `app/components/shared/sidebar_component.css`): below it the mobile chrome (full-bleed frame, hamburger-opened overlay nav drawer); at ≥1024px a two-pane desktop layout (docked left nav rail, no hamburger, full-width top bar, centered content column). Because of this split, feature specs must exercise **both** viewport sizes — there are three distinct testing paths, and new UI work should land in whichever fits:

- **Canonical window sizes** live in `spec/support/viewport_helper.rb` as `ViewportHelper::VIEWPORTS` — `mobile (375×812)` and `desktop (1280×900)` — with a `resize_window_to_viewport(width, height)` helper (mixed into `type: :feature`). Use these; don't hardcode ad-hoc dimensions. The tablet boundary (`768×1024`) is a third, deliberate size used only by `tablet_gm_dashboard_spec` to pin the just-below-desktop overlay case.
- **Path 1 — size-independent invariants run at both sizes.** Anything that must hold everywhere (no horizontal scroll, ≥16px body/textarea text, ≥44px touch targets, contained images, deep-link landing) belongs in a `responsive_*_spec.rb` that iterates `VIEWPORTS.each` inside `context "at #{label}"`, scaling any width bound to the current viewport (`scroll_width <= width`). See `responsive_posts_spec`, `responsive_composer_spec`, `responsive_email_links_spec`. **Do not** add a new mobile-only `type: :feature` spec for a size-independent invariant.
- **Path 2 — behaviour that diverges by size** gets one spec per size, because the assertions are mutually exclusive. Nav chrome is the case: `mobile_nav_spec` (375px — hamburger shown, drawer overlay opens/closes) and `desktop_nav_spec` (1280px — hamburger hidden, drawer docked). Keep them as separate files; don't try to share `it` blocks.
- **Path 3 — viewport-neutral functional specs** (game creation, invitations, sheets, export, request specs, etc.) stay at the default window size — do not dual-size them; it only doubles runtime for identical assertions.

Two traps, both hit here:
- **Capybara `visible:` ignores CSS `transform`.** The mobile drawer is slid off-screen with `translateX(-100%)` but Capybara still reports it visible, so `have_css(..., visible: true)` cannot tell a docked desktop rail from a hidden mobile drawer. Assert on geometry instead — `getBoundingClientRect().left` (0 when docked) or computed `margin-left` (`aside.nav-drawer + div` is `270px` on desktop). Content-only assertions that don't care about position use `visible: :all` (see `sidebar_spec`).
- **Window size leaks across examples** (system specs share one browser). Every viewport-sensitive spec must set its size in a `before` (via `resize_window_to_viewport`), never rely on the size a prior example left behind.
