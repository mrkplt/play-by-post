# CLAUDE.md

## Project Overview

Play-by-Post TTRPG — Rails 8 app for asynchronous tabletop RPGs. GMs and players collaborate on scenes through threaded posts, with email notifications and reply-by-email.

## Reference documents

This file is the standing contract: how to work here, and the rules that apply on every
task. Detail lives in focused documents — **read the one that matches what you are about
to touch, before you touch it.**

| Read before… | Document |
|---|---|
| Writing or changing a ViewComponent, presenter, policy, form, or view | `docs/COMPONENT_CONVENTIONS.md` |
| Touching test infrastructure, chasing a mutant, debugging a suite failure | `docs/TESTING_NOTES.md` |
| Changing gate config or thresholds, or diagnosing a gate failure | `docs/QUALITY_PIPELINE.md` |
| Orienting in the codebase, or changing the domain model | `docs/ARCHITECTURE.md` |
| Visual design — tokens, palette, spacing | `docs/STYLE_GUIDE.md` |
| Anything touching env vars or credentials | `docs/CONFIGURATION.md` |
| Authorization model in depth | `docs/AUTHORIZATION.md` |

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
  dead code, deduping) is part of that task, not a follow-up.
- **Subagents report facts; keep/drop and prioritization are the owner's.** A survey agent
  called four extractions "low value" — from line-count, not measurement — and was wrong:
  it missed that a badge cluster recurred across four files and that buttons bypassed an
  existing primitive. Have agents surface locations, counts, coupling, gate-exposure; make
  the value judgment yourself, and never let an agent's "not worth it" pre-filter what the
  owner sees.
- **Verify agent claims against the code before trusting them.** Review agents in this repo
  hallucinated a "5 existing callers" count (there were zero) and a phantom line-number
  drift. A 10-second grep caught each. Cross-check any load-bearing claim — especially
  file:line references and "X already exists" — before it drives work.
- **A plan handed to an implementer is a spec, not a negotiation history.** Strip the
  discarded options, the "why we chose this," the review-round attributions. Put file:line
  references *inline at the instruction that needs them*, not in an addendum.

### Migration and maintenance

**We move bravely forward.** When functionality changes, it is *migrated* — the old path is
deleted in the same change, not left running beside the new one.

- **Do not leave workarounds, legacy code paths, backups, safety nets, or just-in-case
  scenarios** unless the requirement explicitly asks for one. No compatibility shim for a
  caller that no longer exists, no `if new_thing? … else old_thing end`, no dead method kept
  "in case we need it," no commented-out prior implementation, no feature flag nobody
  requested, no defensive `rescue` around a call that cannot fail. If it is a requirement,
  it is written down as one; otherwise it is not built. Git is the backup.
- **A partial migration is an unfinished migration.** Converting three of twelve call sites
  and leaving nine on the old API creates exactly the debt this repo already paid for.
  Convert every call site, then delete the old thing.
- **Maintain as you go; the gates ratchet up, never down.** Coverage, mutation, typing and
  the static checks improve in the normal course of work. Do not lower a threshold, skip a
  gate, or shrink a diff to keep a weak file out of scope — when a change drags a
  poorly-covered file in, that is the moment to test it.
- **Refactoring is normal work, not a separate project.** Extracting a component, adopting an
  existing primitive, deduping, deleting dead code, updating gems — all in scope for the task
  that touches them. It does not need its own card or permission.
- **Quality over expediency: if we do it the right way, we only do it once.** Given a fast
  path that leaves residue and a correct path that costs more now, take the correct path. If
  the correct path is genuinely out of reach for the task, say so plainly and stop — do not
  ship the fast path quietly.

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
| Dev tools | letter_opener_web |
| Deployment | Coolify (self-hosted) · Docker image built in GitHub Actions, pulled from GHCR |
| Email / LLM / Storage | Resend · OpenRouter · Cloudflare R2 |

Structure, domain model and routes: `docs/ARCHITECTURE.md`.

---

## Development Workflow

1. Write a testing plan in `tests/integration/` (markdown)
2. Write failing RSpec tests
3. Implement until tests pass
4. Verify in browser against the testing plan
5. Push — the pre-push hook runs the fast tier automatically; run `bin/full-check` when you want the heavy tier (system specs, mutation, quality gate) locally instead of waiting on CI

**ALL new features must have tests.**

Two tiers gate the work: `bin/pre-push` (fast, ~30s, runs on every push) and CI /
`bin/full-check` (system specs, mutation, quality gate). Thresholds, gate definitions and
CI topology are in `docs/QUALITY_PIPELINE.md`.

**Rules that apply before you have a reason to open the gate docs:**

- **`--no-verify` is blocked by policy.** Let the hook finish; killing it mid-run leaves the
  ref unpushed.
- **Never read a mutation number from a red suite.** Mutant counts "test failed" as a kill,
  so a broken spec inflates coverage. Confirm `bundle exec rspec` is green first.
- **Run rspec before `bin/quality-metrics --check`.** A mutation run does not write line
  coverage; check without it and every changed file reports `0.0%` — a false failure.
- **`config.eager_load = true` in `config/environments/test.rb` is deliberate**, not the
  Rails default. Do not "restore" the conditional — it hides templateless-ViewComponent
  mutation gaps that only appear on CI.
- **The gates do not run `assets:precompile`; the Docker build does**, with no master key.
  Boot-time code touching Active Storage must be guarded with `unless ENV["SECRET_KEY_BASE_DUMMY"]`.
- **Every new component/presenter goes in `.mutant.yml`** or it is silently unmeasured.
- **Gem maintenance is in scope for any task.** Updatable > 5 ⇒ `bundle update` and commit
  the lockfile. Pinned > 8 ⇒ stop and ask for direction.
- **`master` is squash-merge + delete-branch.** Land follow-ups on a fresh branch off the
  updated `origin/master`, never the merged branch.

### Sorbet checklist (every PR)
- Add `# typed: true` sigil to every new or touched file in `app/`, `lib/`, `config/initializers/`
- Declare explicit `sig` on every method called from a ViewComponent template — `SimpleDelegator` passthrough is invisible to Sorbet
- Use `T.must(value)` for nilable associations known to be present at runtime
- Run `bundle exec srb tc` to confirm zero type errors before pushing
- If new RBI files are needed: `bundle exec tapioca`

---

## Conventions

### Controllers
- Thin — delegate logic to models/services
- Sorbet sigil required; per-action `sig` blocks not needed

### Presenters, components, policies, forms

Full contract in `docs/COMPONENT_CONVENTIONS.md` — read it before writing any of them.
The four rules that decide whether a change is even shaped right:

- **Presenters transform data; components own visual presentation.** A presenter does not
  pick CSS classes; a component does not receive a raw model.
- **Never hand-write bespoke screen markup.** Introduce or extend a ViewComponent, and
  parameterize variations rather than forking a new component.
- **Capability predicates are the public surface of a policy**, named for the game function
  (`manage?`, `resolve?`) — never a role (`gm?`, private) and never a bare CRUD predicate
  borrowed for a different purpose.
- **Every user-editable multi-line text field is a markdown field**, with toolbar and preview.
  There is no "plain textarea for prose."

`bin/check-view-layering` is the enforced statement of the layering rules; its output
explains the contract.

### CSS
- Tailwind only. Co-located component stylesheets live next to their component (`app/components/**/*.css`) and are imported from `app/assets/tailwind/application.css`; add new component CSS there, not in a global sheet.
- Never edit `app/assets/builds/` (generated).
- **Colours have one source of truth: `lib/palette.rb`.** Every colour hex is defined there and nowhere else — CSS, components, JS, and emails all derive from it. Add or change a colour in `lib/palette.rb`, then run `bin/build-palette`. Read `docs/STYLE_GUIDE.md` §1 before touching colour. Corollaries:
  - `app/assets/tailwind/_palette.css` is **generated** (the `@theme` colour block) — never hand-edit it; `bin/check-palette-sync` fails if it drifts.
  - In Ruby (mailers, presenters), read a colour with `Palette[:token]`; never inline a hex. Mailer inline styles come from `MailStylesHelper`, which is sourced from `Palette`.
  - In JS/ERB, use the token utility (`text-muted`, `bg-accent`) — never a raw hex or arbitrary `text-[#…]` value (`bin/check-design-tokens` enforces).

### Sorbet
- `# typed: true` minimum on all new/touched files in `app/`, `lib/`, and `config/initializers/`
- Controllers need the sigil; per-action `sig` blocks not required
- Use `T.must(value)` for nilable associations known to be present at runtime
- Regenerate RBIs: `bundle exec tapioca`
- `config/initializers/*` doing metaprogramming are `# typed: false` and are not gate-checked — the safe home for framework patches

### Testing
- Request specs: `spec/requests/`, one file per controller
- Auth in request specs: `sign_in(user)` — bypasses all controller code, goes directly through Warden
- Magic link flow in specs: `Devise::Passwordless::SignedGlobalIDTokenizer.encode(user)` → `GET user_magic_link_path, params: { user: { email: user.email, token: token } }`
- Cross-authentication callbacks (e.g. updating `last_login_at`) belong in `config/initializers/warden_hooks.rb` via `Warden::Manager.after_set_user` — not in `Users::SessionsController`, which is not in the call path for magic link sign-ins
- Time-travel is **Timecop**, not `ActiveSupport::Testing::TimeHelpers` (not mixed in here)
- **Restore any global you mutate** (especially `ActiveJob::Base.queue_adapter`) in an `around`/`ensure` — a leak here silently broke 37 specs once
- Feature specs must exercise both viewports (1024px breakpoint); technique and traps in `docs/TESTING_NOTES.md`
