# BYOK lifecycle — fully in place, no page refresh (Fizzy #120)

## Requirement
The entire BYOK OpenRouter key lifecycle — generate keypair → save (seal) key →
delete key — happens in place on the Profile screen. No step may cause or require a
page refresh or a full Turbo visit.

## What was wrong
- **Create**: the pending spinner waited on an ActionCable broadcast
  (`KeypairReadyBroadcast` via `ByokKeyChannel`); in production the broadcast never
  arrived and only a reload revealed the paste form. The subscribe-time replay
  (PR #269) did not resolve it in production.
- **Save / Delete**: `#update` and `#destroy` redirected to the profile, bouncing the
  whole page.

## Fix
- The cable path for BYOK is deleted (`ByokKeyChannel`, `KeypairReadyBroadcast`, the
  job's broadcast). The pending spinner now **polls**: a `frame-poll` Stimulus
  controller reloads the control's Turbo Frame (GET `profile_byok_key_path` →
  `#show`) every second until the job's outcome renders the paste form —
  deterministic regardless of websocket health.
- `#create`, `#update`, `#destroy` all respond with Turbo Streams that swap the
  control frame to its next state + a toast. No redirects.
- Saving/deleting a key also refreshes the "Fund AI for your games" section in
  place, since its visibility depends on key presence.

## RSpec coverage
- **System (real Chromium)** `spec/system/byok_key_seal_spec.rb`:
  - Full lifecycle — set up encryption → paste + save → delete — with a
    `document.body.dataset` marker asserting the body was never replaced (no full
    page load, no Turbo visit).
  - Polling path — controller held on the pending branch, spinner resolves to the
    form via frame poll.
  - Existing WebCrypto seal/interop specs, updated for stream responses.
- **Request** `spec/requests/profiles/byok_keys_spec.rb`: `#show` renders the
  control frame (pending vs form); `#create`/`#update`/`#destroy` respond with
  turbo streams targeting the control frame (and funding section), no redirects.
- **Component**: pending state renders the poll controller wiring.
- Channel and broadcast specs deleted with their classes.

## Browser verification (production, after deploy)
1. Profile → no keypair → "Set up encryption" → spinner resolves to the paste form
   within ~1–2s, no reload.
2. Paste a key → "Save key" → control shows key-present state in place; "Fund AI
   for your games" section appears; no page bounce.
3. "Delete key" → control returns to "Set up encryption" in place; funding section
   disappears; no page bounce.
