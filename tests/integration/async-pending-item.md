# Integration test plan — async "pending backend item" UI (Fizzy #115/#116)

A generic Hotwire capability: when a page shows an item that a background job is still
creating, the viewer sees a **spinner + "Waiting…" message** that is swapped for the real
content when the job broadcasts it, with a **completion toast**. State is nothing more than
*presence on the page*: reload/navigate-away and you are treated like any other viewer.

First (only current) consumer: **AI scene summaries** — `SceneSummaryJob` runs in the
worker after a scene is resolved on an AI-enabled game; until it writes the `SceneSummary`
row, the scene page shows the pending state instead of an empty region, and when the job
finishes the finished summary is pushed to the page.

> Scope note: #112 / BYOK (`AiKeypairGenerationJob`, `AiKeyResolver`) has **not** merged.
> The component is built generically so the keypair job can adopt it unchanged, but scene
> summaries are the only consumer wired up here.

## Mechanism (decided — broadcasts, not polling)

- **A Turbo Frame that subscribes to a signed Turbo Stream** via `turbo_stream_from`
  (`Shared::AsyncPendingComponent`). The frame ships with NO `src` — it just waits. When the
  worker finishes the job it broadcasts a `turbo_stream.replace` targeting the frame id
  (`scene_summary_pending`) over **Action Cable backed by Solid Cable** (`config/cable.yml`,
  the `cable` DB on the shared `dbdata` volume — see `docs/CONFIGURATION.md` "Four SQLite
  databases"). Every subscribed viewer's frame is replaced in place. The completion toast is
  a second broadcast targeting `#toast_layer`.
- **Per-viewer visibility is handled by partitioning the stream, not by re-rendering per
  request.** A summary is visible differently to different viewers — a *draft* → managers
  only; an *AI-generated* summary → hidden from a viewer whose display preference is
  `hidden` (`SceneSummary#visible_to?`). So the page subscribes each viewer to
  `[scene, :summary, <their visibility class>]` (`SceneSummaryVisibility`:
  `manager` / `plain` / `hidden`), and `SceneSummaryBroadcast` broadcasts only to the
  classes entitled to see the summary — never to a class that must not see it. Those viewers
  keep waiting, exactly as the page would have gated them.
- **Subscription authorization:** `SceneSummaryChannel` verifies the signed stream name AND
  confirms the connecting user is actually entitled to the class they requested (a `plain`
  viewer replaying a `manager` stream name is rejected; a non-member is rejected).

## Scenarios

### A. GM on a resolved, AI-enabled scene, job still running
1. Resolve a scene on an AI-summaries-enabled game; do not let the job finish.
2. Visit the scene as the GM → **spinner + "Generating scene summary…"**, `#scene_summary_pending` present, a `<turbo-cable-stream-source>` subscribed to the `manager` stream.
3. Finish the job (write the `SceneSummary`, run `SceneSummaryBroadcast`) → the frame is replaced with the summary in place, **"Scene summary ready." toast** appears, spinner gone.
4. Both viewports (1024px breakpoint).

### B. Player (plain) vs. hidden-preference player
- A **plain** player waiting sees a published summary swap in when broadcast; an AI summary swaps in too.
- A **hidden**-preference player never receives an AI summary broadcast — their frame keeps waiting even after the GM's did swap.
- A **draft** summary reaches only the GM's `manager` stream; a player's frame keeps waiting until publish.

### C. AI summaries off
- Resolved scene, AI summaries disabled → **no pending frame at all** (`#scene_summary_pending` absent), and the GM still sees the manual **"Write Summary"** action.

### D. Subscription auth (channel)
- Manager → manager stream: **confirmed**. Plain player → plain stream: **confirmed**.
- Plain player → manager stream: **rejected**. Hidden player → plain stream: **rejected**.
- Non-member → any stream: **rejected**. Missing scene: **rejected**.

## Automated coverage
- Model: `spec/models/scene_summary_visibility_spec.rb`, `spec/models/scene_summary_broadcast_spec.rb`, `spec/models/scene_summary_spec.rb` (`visible_to?`).
- Channel: `spec/channels/scene_summary_channel_spec.rb`.
- Job: `spec/jobs/scene_summary_job_spec.rb` (broadcasts after upsert).
- Component/presenter/service: `async_pending_component_spec.rb`, `scene_screen_presenter_spec.rb`, `scene_show_builder_spec.rb`.
- Request: `spec/requests/scene_summaries_spec.rb`, `spec/requests/scenes_spec.rb` (Write Summary vs. pending frame).
- System (both viewports): `spec/system/async_scene_summary_spec.rb` — real browser cable subscription + broadcast swap.
