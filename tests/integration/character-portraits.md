# Integration Testing Plan — AI Character Portraits (Fizzy #19)

A player generates an AI portrait image for their own character from a markdown prompt, via
an OpenRouter image model, funded from the game's contribution pool. On a provider moderation
refusal, a static "pervert" placeholder is forced as the current portrait and the character's
portrait is permanently locked.

See `plan-1.md` for the full design. This document is the manual/acceptance testing plan;
the automated coverage is enumerated in §8 of the plan.

## Preconditions

- A game with a GM and at least two players (P1 owns character C1; P2 is another member).
- At least one member has a BYOK OpenRouter key authorized for `character_portrait` in the
  game (so the pool is non-empty). A second scenario: the pool is empty.
- The GM has optionally designated an environment/setting Page in game settings.

## Scenarios

### 1. Happy path — player generates a portrait
1. As P1, open C1's character sheet. The portrait library shows a "Generate portrait" affordance.
2. Click it; a form opens with a **markdown** prompt field (toolbar + preview).
3. Enter a clean character description; submit.
4. The sheet updates **in place** (no full navigation) to a "generating…" state, then to the
   new image appearing in the library.
5. **Expect:** a new `CharacterImage` with an attached PNG; it is **not** automatically the
   current portrait; an `AiGeneration` audit row exists with `requested_by` = P1 and
   `funded_by` = whichever pool member's key paid (may be P2, may be P1).
6. P1 can then mark the generated image current via the existing control.

### 2. Moderation blocks a disallowed prompt (pre-generation)
1. As P1, generate with a prompt that trips OpenAI's Moderation API (simulated via a stubbed
   `Ai::Moderation` returning a flagged `Verdict` in tests).
2. **Expect:** generation is **blocked before any key is spent** — no image is generated,
   nothing is persisted, the character's portrait is unchanged.
3. **Expect:** a benign error toast to the player; an operator log line with the flagged
   category names and the game/player prompt parts.
4. **Expect:** no `Ai::Funding` call and no `AiGeneration` row. No lock, no placeholder — the
   player may simply try a different prompt.

### 3. Empty pool / no funding
1. Ensure no member has an authorized key for `character_portrait` in the game.
2. As P1, attempt to generate.
3. **Expect:** a plain, non-punitive failure toast ("no funding available" style). No lock,
   no placeholder, no `CharacterImage`, nothing changed.

### 4. Network / provider error (non-moderation)
1. Simulate a network/HTTP failure from the image endpoint (not a moderation refusal).
2. **Expect:** a plain failure toast; nothing persisted; no lock; no placeholder.

### 5. Authorization
1. As P2 (not C1's owner), confirm there is no way to trigger generation for C1.
2. As the GM, confirm the GM cannot generate a portrait for C1 (portraits are player-curated).
3. Both are denied (redirect on an auth denial, per the Turbo-boundary rule).

### 6. GM environment/setting Page
1. As the GM, open game settings; designate one of the game's pages as the environment Page.
2. **Expect:** only this game's pages are listed; the picker is GM-only.
3. Generate as P1; the composed prompt includes the env-Page body (verified in unit specs).
4. Clear the designation; generation still works with only the safety + player prompt.

### 7. Contribution matrix
1. As a member, open the key-contribution matrix for the game.
2. **Expect:** `character_portrait` appears as a pool-fundable column (label "Character
   portraits"); authorizing/deauthorizing a key for it works.

## Viewports
Exercise the generate form and the in-place library update at **both** viewports (≥1024px and
below the 1024px breakpoint), per `docs/TESTING_NOTES.md`.

## Notes
- `Ai::ImageRequest` is the stubbed seam for the provider-refusal shape; job/lock/placeholder
  behavior is tested against a stub that raises `Refused` on demand and does not depend on the
  real OpenRouter payload (see plan §7).
