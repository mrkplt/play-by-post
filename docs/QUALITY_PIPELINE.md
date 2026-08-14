# Quality Pipeline

**Read when:** a gate fails, or you are changing gate configuration, thresholds, or CI workflow.
For technique — killing mutants, getting specs off the database, suite-level traps — see `docs/TESTING_NOTES.md`.

---

## The two tiers

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

## Quality Gates

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

## Gem Maintenance

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

