# Plan: Remove Lookbook (#86)

Fizzy: http://fizzy.10.0.0.233.sslip.io/1/cards/86

## Goal

Lookbook (the browsable component gallery, dev-only at `/lookbook`) is unused, and the
30 preview files under `spec/components/previews/` are never exercised by any spec — a
broken preview stays invisible until someone opens the gallery. Remove Lookbook, its
previews, and the per-component "add a preview" convention, deleting the standing tax.

## Verified scope (survey done pre-plan)

- Previews are `add_filter "/spec/"`'d out of SimpleCov → deletion does **not** shift coverage.
- No CI job renders previews; no companion `.erb` templates; no preview classes in `.mutant.yml`.
- `config/initializers/view_component.rb`'s only job is registering `preview_paths` for Lookbook → delete the whole file (confirmed with owner).
- Doc references live in 5 docs + CLAUDE.md; COMPONENT_CONVENTIONS.md:48 already has a *stale* preview path.

## Tasks

### Code / config
- [ ] `git rm -r spec/components/previews/` (30 files + `shared/`, `ui/` dirs)
- [ ] Remove `gem "lookbook"` from `Gemfile`, then `bundle install` (drops it + deps from lockfile)
- [ ] Remove `mount Lookbook::Engine` line + comment from `config/routes.rb`
- [ ] Remove Lookbook comment block + `config.lookbook.project_name` from `config/environments/development.rb`
- [ ] Delete `config/initializers/view_component.rb` entirely

### Docs
- [ ] `.claude/CLAUDE.md` — drop "Lookbook (component previews)" from Dev tools row
- [ ] `docs/COMPONENT_CONVENTIONS.md` — delete the "Documentation:" block (stale preview path + `/lookbook`)
- [ ] `docs/STYLE_GUIDE.md` — remove "See it live / `/lookbook`" block + "add a Lookbook preview" clause
- [ ] `docs/QUALITY_PIPELINE.md` — drop "browse the component gallery at `/lookbook` (dev)"
- [ ] `docs/ARCHITECTURE.md` — drop "· Lookbook (component previews)"
- [ ] `bin/check-view-layering:687` — drop "previews" from the comment's construction-site list

### Verification
- [ ] `bundle exec srb tc` → zero type errors
- [ ] `SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile` exits 0
- [ ] `bin/rails runner "1"` (dev) boots — routes/initializer removal doesn't error
- [ ] `bundle exec rspec` green + `bin/pre-push`
- [ ] Browser: a page renders with styling intact
- [ ] Gem maintenance: check updatable count while bundle is open (>5 ⇒ `bundle update`)

## Open questions

- None. Initializer deletion confirmed.
