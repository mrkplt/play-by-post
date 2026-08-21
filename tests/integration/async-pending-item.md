# Integration test plan — async "pending backend item" UI (Fizzy #115)

A generic Hotwire capability: when a page shows an item that a background job is still
creating, the viewer sees a **spinner + "Waiting…" message** that polls and swaps in the
real content when it lands, with a **completion toast**. State is nothing more than
*presence on the page*: reload/navigate-away and you are treated like any other viewer.

First (only current) consumer: **AI scene summaries** — `SceneSummaryJob` runs in the
worker after a scene is resolved on an AI-enabled game; until it writes the `SceneSummary`
row, the scene page has to show the pending state instead of an empty region.

> Scope note: #112 / BYOK (`AiKeypairGenerationJob`, `AiKeyResolver`) has **not** merged.
> The component is built generically so the keypair job can adopt it unchanged, but scene
> summaries are the only consumer wired up here.

## Mechanism (decided)

- **Turbo Frame driven by a generic `job-status` Stimulus controller**, which re-fetches
  the poll path on an interval (the frame ships with NO `src`: a self-referential `src`
  no-ops on eager load and empties the frame, so the controller owns fetching). No Action
  Cable / broadcasts — this repo has no `config/cable.yml` and no `solid_cable`/Redis, and
  the worker is a separate container. Polling needs no infra and is identical for any
  future consumer.
- The poll endpoint returns **the spinner frame (with the controller) while the item is
  absent** and **the finished content frame (no controller) once it exists** — Stimulus
  disconnects on that swap and polling stops. The completion toast rides a
  `turbo_stream.replace "toast_layer"` **inside** the ready frame (Turbo runs any stream
  element the moment it connects to the DOM, so it lands even though a frame navigation
  ignores sibling streams).

## Component / endpoint under test

- `Shared::AsyncPendingComponent` (generic): wraps a Turbo Frame with a poll `src` +
  interval; renders `Ui::SpinnerComponent` + a caller-supplied waiting message as the
  pending body; caller supplies the ready content (slot) and the frame id.
- `job-status` Stimulus controller: reloads the frame on an interval, stops when the
  response frame drops the `data-job-status-polling` marker, then dispatches a toast.
- Scene summaries consume it: `scenes#show` renders the pending component when the scene
  is resolved + `ai_summaries_enabled?` + no `SceneSummary` row yet; the poll hits a
  summary status endpoint that returns the spinner while absent and
  `Shared::SceneSummaryComponent` once present.

## Cases

### Request/endpoint
1. **Pending** — resolved AI-enabled scene, no summary row → status endpoint responds with
   a turbo-frame containing the spinner + "Waiting…" and the `data-job-status-polling`
   marker.
2. **Ready** — summary row exists → status endpoint responds with the same frame id but the
   rendered summary and **no** polling marker (poller stops).
3. **Draft visibility preserved** — a draft (unpublished) summary is "ready" only for a GM;
   a non-GM viewer of a draft-only scene still gets the pending spinner (matches existing
   `summary_visible?` rule), never the draft body.
4. **Not applicable** — AI disabled, or scene not resolved → no pending frame rendered on
   `scenes#show` at all (no polling), summary region behaves as today.
5. **Auth** — the status endpoint is scoped exactly like the existing scene_summary routes
   (game membership / visibility); a non-member gets the same rejection as `scenes#show`.

### Component (`render_inline`)
6. Pending render includes the spinner, the waiting message text, the frame id, the poll
   `src`, and the `data-job-status-polling` marker.
7. Ready render (given ready content) shows the content and omits the polling marker.
8. Waiting message is caller-supplied (parameterized), not hard-coded to summaries.

### Stimulus / system (both viewports — mobile <1024, desktop ≥1024)
9. GM resolves an AI-enabled scene → lands on `scenes#show` → sees spinner + "Waiting…".
10. Once the job writes the summary (simulate by creating the row), the next poll swaps the
    spinner for the summary body **in place** (no full reload) and a completion toast
    appears.
11. Reload while pending → still just the spinner (no persisted per-user state); another
    viewer opening the same pending page also sees the spinner (presence, not initiator).
12. Poller stops after the swap (no continued network requests against the ready frame).

## Out of scope
- No WebSocket/broadcast path. No persistence of "who initiated". No notify-when-away.
- BYOK keypair consumer (not in this repo yet) — capability only.
