# BYOK pending spinner — replay on subscribe (Fizzy #120)

## Bug
Clicking "Set up encryption" swaps in the pending spinner, but the spinner can hang
forever: `KeypairGenerationJob` often finishes (and broadcasts the paste form) before
the browser's ActionCable subscription to `[owner, :byok_keypair]` is confirmed.
ActionCable drops broadcasts with no subscriber, nothing replays them, and only a page
reload reveals the form.

## Fix
`ByokKeyChannel#subscribed` replays `KeypairReadyBroadcast` after accepting the
subscription when the keypair already exists and no key is sealed yet — exactly the
state the broadcast renders. Either the job finishes after subscribe (normal broadcast
arrives) or before (the channel replays at subscribe time). The frame replace is
idempotent, so the tiny both-fire window is harmless.

## RSpec coverage
- `spec/channels/byok_key_channel_spec.rb`
  - subscribing with an existing unsealed keypair replays the ready broadcast
    (pending frame + toast targets on the owner's stream)
  - subscribing with no keypair broadcasts nothing (job still running — normal path)
  - subscribing with a sealed key broadcasts nothing (paste form would be false)
  - existing authorization cases unchanged

## Browser verification
1. Profile → AI settings, no keypair present.
2. Click "Set up encryption".
3. The spinner must resolve to the paste-a-key form **without reload** — even when the
   job wins the race (dev's in-process job runner makes the job finish almost
   instantly, which is the racy case).
4. Paste form accepts a key; save works as before.
