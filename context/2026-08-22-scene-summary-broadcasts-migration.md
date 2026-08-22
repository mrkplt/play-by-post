# Migrate async scene-summary UI from polling → Solid Cable broadcasts (Fizzy #115/#116)

Branch: `fizzy-115-async-pending-ui` (redo in place — PR #261 becomes the broadcasts PR).

## Decision (settled)
- Replace the poll-based async-pending mechanism from #261 with **Turbo Stream broadcasts over
  Solid Cable**. The cable DB lives on the already-shared `dbdata:/data` volume alongside
  `queue`/`cache` — no new web↔worker coupling, no touch to the worker-only `aikeysdata` volume.
- Verified against `docker-compose.yml`: web+worker both mount `dbdata:/data`; only worker mounts
  `aikeysdata`. #116's infra premise holds.
- `action_cable/engine` is currently commented out in `config/application.rb` — this migration
  turns it on. `@rails/actioncable/src` is already pinned in `config/importmap.rb`.

## Per-viewer visibility — the Turbo Streams convention (from turbo-rails docs)
A summary's visibility differs per viewer: a **draft** is visible only to a manager; an
**AI-generated** summary is hidden from a viewer whose display preference is `hidden`
(`SceneSummary#visible_to?`). The idiomatic Turbo answer:
- **Scope the stream name by visibility class.** `turbo_stream_from` produces a cryptographically
  signed stream name; a client cannot subscribe to a stream it was not served. Each viewer
  subscribes to `[scene, :summary, <visibility_class>]` where the class is derived from the same
  `visible_to?` rules. The worker broadcasts only to the classes that should see the summary —
  never the `hidden` class, never `plain`/`hidden` for a still-draft summary.
- **Authorize the subscription** in a custom channel (`subscribed` + `subscription_allowed?` +
  `reject`), re-checking the viewer's class — matches this app's Pundit gate shape.

Visibility classes for a scene summary:
- `manager` — GM/manager of the game (sees drafts + published, AI badge honoured separately).
- `plain`  — non-manager, display preference NOT hidden (sees published, incl. AI).
- `hidden` — non-manager, display preference hidden (sees published NON-AI only).

`visible_to?` maps onto these:
- draft summary → visible only to `manager`.
- published + AI-generated → `manager` + `plain` (NOT `hidden`).
- published + non-AI → all three.

## Work

### 1. Infra — turn Action Cable on, add Solid Cable
- `config/application.rb`: uncomment `require "action_cable/engine"`.
- `Gemfile`: add `gem "solid_cable"`; `bundle install`.
- `config/cable.yml`: `production` → `adapter: solid_cable`, `connects_to: { database: { writing: cable } }`,
  `polling_interval`. `development`/`test` → `adapter: async` (no DB, matches how the app runs
  cable-less today; async is in-process and needs no cable DB).
- `config/database.yml`: add `cable` sub-db to `production` mirroring `cache`/`queue`
  (`database: .../production_cable.sqlite3`, `migrations_paths: db/cable_migrate`,
  `schema_dump: cable_schema.rb`).
- `db/cable_schema.rb` + empty `db/cable_migrate/` (schema-owned, like cache/queue).
- `app/channels/application_cable/connection.rb` + `channel.rb` (Rails defaults; identify by
  Warden user so subscription auth can read `current_user`).
- CONFIGURATION.md: document the `cable` DB (new config read site — authoritative file, same
  commit). ARCHITECTURE.md: note the broadcast path.

### 2. Visibility-class helper (single source, reused by view + worker)
- `SceneSummary.visibility_class_for(policy_or_manager_flag, viewer)` OR a small
  `SceneSummaryVisibility` module returning `:manager | :plain | :hidden`. Reuse the exact
  `visible_to?` rule inputs (draft?/manage?, ai_generated?, viewer hidden?). One definition; the
  scene page derives the *viewer's* class, the worker derives the *set of classes* that should
  receive the summary.

### 3. Custom channel for subscription auth
- `Turbo::StreamsChannel` subclass (or configured channel) that verifies the signed stream name
  AND checks the connection's user is entitled to the requested visibility class for that scene.
  `reject` otherwise. `turbo_stream_from [scene, :summary, klass], channel: <ThisChannel>`.

### 4. Scene page renders a subscribed pending frame
- `scenes/show.html.erb` pending branch: keep `Shared::AsyncPendingComponent` but drive it by a
  `turbo_stream_from` subscription (viewer's class) instead of a poll `src`.
- `Shared::AsyncPendingComponent`: drop the `poll_path`/`interval_ms`/`Poll`/`job-status` wiring;
  take a `stream` streamable (or pre-rendered subscription tag). Frame id stays
  `scene_summary_pending` so the broadcast `replace` targets it.

### 5. Worker broadcasts on completion
- `SceneSummaryJob#perform` (after upsert): for each visibility class that should see the new
  summary, `Turbo::StreamsChannel.broadcast_replace_to [scene, :summary, klass], target:
  "scene_summary_pending", ...` rendering `Shared::SceneSummaryComponent` for that class's view,
  PLUS a toast stream to `#toast_layer` (broadcast_replace_to the same class stream). Never
  broadcast to a class that must not see it.
- Broadcast rendering must not depend on a request; render the component with an explicit
  presenter built in the job (no `helpers`/request context). Confirm `SceneSummaryPresenter` can
  be built job-side (urls via `Rails.application.routes.url_helpers`, policy via
  `SceneSummaryPolicy.new(viewer_or_nil, summary)` — but broadcasts are per-class, not per-user, so
  the component must render from class, not a specific viewer; verify `SceneSummaryComponent` only
  needs class-level facts: status label, badge, manage affordances → manage only in `manager`
  stream).

### 6. Retire polling — delete, don't run both
- Delete: `app/javascript/controllers/job_status_controller.js`,
  `app/views/scene_summaries/status.html.erb`, the `status` action + `status_poll_path` helper in
  `SceneSummariesController`, the `get :status` route, and the `summary_status_path` /
  `summary_pending` plumbing in `SceneShowBuilder` / `SceneScreenPresenter` that only existed to
  feed the poll frame (keep `summary_pending?` — still needed to decide "show the waiting frame").
- Keep `Ui::SpinnerComponent`, `Shared::AsyncPendingComponent` (rewired),
  `SceneSummary#visible_to?`.

### 7. Tests / gates / mutation
- Convert `spec/requests/scene_summaries_spec.rb` status specs → remove (endpoint gone).
- `spec/system/async_scene_summary_spec.rb`: assert the summary appears via broadcast (drive the
  job in-process, both viewports).
- New: job broadcast specs (per class: manager gets draft, plain doesn't; hidden never gets AI);
  channel subscription auth spec (reject wrong class); visibility-class helper spec.
- `.mutant.yml`: register the new visibility helper + channel; drop the deleted subjects.
- Sorbet sigils on all touched/new app files; `bundle exec srb tc` clean.
- CONFIGURATION.md cable-DB entry; keyless Docker asset-precompile guard still holds (Action Cable
  loading must not need the master key at precompile — verify `SECRET_KEY_BASE_DUMMY` boot).

## Sequencing
1 → 2 → 3 → 4/5 → 6 → 7. Then commit, push, watch gates, remediate to green.
