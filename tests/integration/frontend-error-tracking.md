# Frontend error tracking (GlitchTip) — Fizzy #83

Track **frontend JavaScript errors** in the same self-hosted GlitchTip the backend
already reports to. The backend side (`config/initializers/sentry.rb`, `sentry-ruby`)
is done; this adds the browser side.

## The constraint that shapes everything

GlitchTip is self-hosted on PiHost and **has no public ingress** — it is reachable only
over the internal backplane. The backend Ruby SDK reports server-to-server across that
backplane. A browser SDK runs on the player's machine on the public internet and cannot
reach GlitchTip directly. So browser events are **tunnelled through the Rails app**,
which can reach GlitchTip internally — the same shape as `CoolifyDeployJob` forwarding to
the (also private) Coolify.

## Decisions (settled)

- **Delivery:** the versioned Sentry browser bundle from `browser.sentry-cdn.com`
  (errors-only `bundle.min.js`, pinned to 10.70.0 with an SRI hash). No tracing/replay/
  sessions — GlitchTip does not support them.
- **Transport:** the SDK's `tunnel` option points at a same-origin path
  (`/errors/tunnel`). The DSN host is never contacted from the browser.
- **DSN:** reuse the existing `glitchtip.dsn` / `GLITCHTIP_DSN`, resolved through
  `ErrorTracking` (the single source of truth, shared with the backend initializer).
- **Forwarding:** the tunnel controller validates the envelope against our DSN, then
  enqueues `ErrorEnvelopeForwardJob`, which POSTs the raw envelope to GlitchTip's
  `/api/<project_id>/envelope/` over the backplane (with retries).

## Surfaces

- `app/models/error_tracking.rb` — DSN resolution + `parsed_dsn`.
- `app/models/glitch_tip_dsn.rb` — parses a DSN into host / project id / ingest URL.
- `app/controllers/error_tunnel_controller.rb` — public, unauthenticated
  `POST /errors/tunnel`; drops anything not addressed to our own DSN (no open relay).
- `app/jobs/error_envelope_forward_job.rb` — forwards the envelope to GlitchTip.
- `app/views/layouts/application.html.erb` — loads + inits the browser SDK, gated on a DSN.
- `config/routes.rb` — the tunnel route, in the `web` runtime mode.

## Acceptance

1. **DSN unset (dev/CI/test default):** page source has no Sentry bundle and no DSN.
   `POST /errors/tunnel` drops everything (422).
2. **DSN set:** the layout loads the pinned bundle before `javascript_importmap_tags`
   and inits with `dsn` + `tunnel: "/errors/tunnel"`.
3. **Tunnel security:** an envelope addressed to a different host or project id, or with
   a malformed/absent DSN, is dropped (422, no job). Only an envelope addressed to our
   DSN enqueues the forward job (200).
4. **Forward:** the job POSTs the raw envelope bytes to the DSN's
   `/api/<project_id>/envelope/` with `Content-Type: application/x-sentry-envelope`; a
   non-2xx response is logged, not raised; a missing DSN discards the job.

## Manual browser verification

With a DSN configured locally (`GLITCHTIP_DSN=…`) and reachable GlitchTip:

1. Load any page; confirm the Sentry bundle is present in `view-source` and the init
   names `/errors/tunnel`.
2. Throw an uncaught error: `setTimeout(() => { throw new Error("fe-test #83") })`.
3. Confirm a `POST /errors/tunnel` in the network tab (same-origin) and the event
   arriving in the GlitchTip project.
4. Unset the DSN, reload: confirm no bundle loads and no `Sentry` global exists.
