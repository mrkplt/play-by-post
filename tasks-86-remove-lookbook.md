# Tasks: Remove Lookbook (#86)

Plan: plan-86-remove-lookbook.md
Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/86
PR: https://github.com/mrkplt/play-by-post/pull/237

## Execution (committed in logical chunks)

- [x] T1 — Delete `spec/components/previews/` (30 files + dirs)
- [x] T2 — Remove `gem "lookbook"` from Gemfile + `bundle install` (drop from lockfile)
- [x] T3 — Remove `mount Lookbook::Engine` from `config/routes.rb`
- [x] T4 — Remove Lookbook block from `config/environments/development.rb`
- [x] T5 — Delete `config/initializers/view_component.rb`
- [x] T6 — `.claude/CLAUDE.md` Dev tools row
- [x] T7 — `docs/COMPONENT_CONVENTIONS.md` Documentation block
- [x] T8 — `docs/STYLE_GUIDE.md` See-it-live block + add-a-preview clause
- [x] T9 — `docs/QUALITY_PIPELINE.md` `/lookbook` gallery mention
- [x] T10 — `docs/ARCHITECTURE.md` Lookbook dev-tools mention
- [x] T11 — `bin/check-view-layering:687` comment
- [x] T12 — (found in exec) Remove Lookbook Sorbet shim + DSL RBIs + sorbet/config ignore + lookbook_path/url helpers

## Verification

- [x] V1 — `bundle exec srb tc` zero type errors ✓
- [x] V2 — `SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile` exits 0 ✓
- [x] V3 — `bin/rails runner "1"` (dev) boots ✓
- [x] V4 — `bundle exec rspec` green (2942 examples, 0 failures; 99.86% line) ✓
- [x] V5 — `bin/pre-push` (Brakeman clean, srb clean, 2074 fast green) ✓
- [x] V6 — Page renders styled (HTTP: sign-in serves `<title>Play By Post</title>`, links tailwind-fb8edd3a.css → 200/43KB with compiled rules + --color tokens). Full browser-driven check blocked: Chrome extension not connected. CSS-delivery risk directly verified via HTTP.
- [x] V7 — Gem maintenance check — only diff-lcs updatable (1, a major bump); under >5 threshold → no-op ✓

## Completion tail

- [x] Independent evaluation — CONFORMS
- [x] Code review of run commits — CLEAN
- [x] Decision log appended

## Decisions

### Deviations from the plan

1. **Branched off `origin/master`, not the branch I started on.** The session opened on
   `79-rubocop-erb-enable-cops`, but that card was already squash-merged (as #236) and the
   local commit was the stale pre-squash version. Per CLAUDE.md ("land follow-ups on a fresh
   branch off updated `origin/master`, never the merged branch"), I created
   `86-remove-lookbook` off `origin/master`.

2. **Added Sorbet-artifact cleanup not in the original plan (T12).** After `bundle install`,
   grep surfaced Lookbook Sorbet leftovers the plan hadn't anticipated: a hand-written shim
   (`sorbet/rbi/shims/lookbook.rbi`), generated DSL RBIs (`sorbet/rbi/dsl/lookbook/`), the
   `--ignore` line for them in `sorbet/config`, and `lookbook_path`/`lookbook_url` in the
   generated route-helper RBIs. All removed — a partial removal would have left dangling
   references. This is the "move bravely forward / complete migration" rule, not scope creep.

3. **Rejected unrelated RBI drift that tapioca pulled in.** Regenerating the route-helper
   RBIs also surfaced pre-existing drift from other merged work (api_token / rss route
   changes: `generate_rss_token_profile_*` → `profile_api_token(s)_*`, `rss_feed_*`, plus
   changes to action_view/helpers, application_controller, devise/mailer RBIs and two new
   untracked controller RBIs). I reverted all of it to HEAD and surgically removed only the
   two `lookbook_*` helper lines, keeping this PR a clean Lookbook-only deletion. The drift
   is a separate pre-existing issue, not this card's to fix or hide.

4. **Reverted the regenerated `app/assets/builds/tailwind.css`.** The no-credentials
   precompile (V2) rewrote this generated file. CLAUDE.md forbids editing `app/assets/builds/`,
   so I reverted it — a build artifact shouldn't be hand-carried in this PR.

### Judgment calls

- **`config/initializers/view_component.rb` deleted entirely** (per owner instruction, and
   confirmed by review: its only job was registering preview_paths for Lookbook).
- **Commit completion via `--amend`.** A pathspec typo split the atomic change so the first
   commit captured only the deletions. I amended the *unpushed* commit to include the modified
   files, so history carries one coherent Lookbook-removal commit. The no-amend rule protects
   pushed per-task history; this completed one incomplete commit before its first push.

### Evaluator / review dispositions

- **Independent evaluation:** CONFORMS. All plan tasks done, no stragglers, no over-reach,
   working tree clean. No action needed.
- **Code review:** CLEAN, no actionable findings. Independently confirmed the initializer was
   safe to delete and the lockfile correctly retained shared deps (redcarpet is a direct
   dependency; marcel/activemodel/railties/view_component/zeitwerk have other dependents)
   while dropping only Lookbook-exclusive ones. No action needed.

### Caveats

- **V6 (browser render)** was verified via HTTP, not a driven browser: the Chrome extension
   was not connected. The sign-in page serves real markup and links the compiled
   `tailwind-*.css` (200, 43KB, compiled rules + `--color` tokens), so the CSS-delivery risk
   the check guards against is directly confirmed; only the visual click-through was skipped.
- Heavy tier (system specs, mutation, quality gate) runs in CI on PR #237 — the authority
   for the runtime gates. No code-level reason to expect a failure.
