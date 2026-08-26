# Key ownership refactor — a person owns a key; a game only *uses* people's keys

## Context

Superseding Fizzy #114 (funding policy/ledger — set aside). Shaping #114 surfaced the real
tension: **the shipped custody model lets a `Game` own a key, and that is wrong.** A key
is real money; **only a person can own a key.** A game does not own a key — one or more
*people* own keys and **make them available** for a game to use. Ownership is a person all
the way down.

## Ground truth found in the code

- `EncryptedValue.owner` is polymorphic `User | Game` (`app/models/encrypted_value.rb`,
  schema `encrypted_values.owner_type/owner_id`).
- `Game#ai_key_present?` (`app/models/game.rb:125`) queries an `openrouter_key`
  `EncryptedValue` with `owner: self` — a **game-owned** key. `StoredKeySource#for_game`
  (`app/services/crypto/stored_key_source.rb`) decrypts it; `AiKeyResolver#resolve`
  (`app/services/ai_key_resolver.rb:65`) has a `game.ai_key_present? → for_game` branch.
- **A game-owned key is a phantom — it can never be created.** The only enqueue of
  `KeypairGenerationJob` hardcodes `owner_type: "User"`
  (`app/controllers/profiles/byok_keys_controller.rb:31`); no route/UI creates a
  game-owned key. The entire game-key path is latent infrastructure exercised only by
  stubs. **So this is not a data migration — there are no game-owned rows to move.**
- A game has exactly one `game_master` but many members (`Game#game_master`,
  `game.rb:71`; `GameMember::ROLES` player/game_master). GM-only game settings flow
  through `GamePolicy#manage?` from `Games::SettingsController`.
- Custody split is already tier-enforced: **only `worker` can decrypt a `PrivateKey`**
  (`web` gets `PrivateKeyEncryption::UnavailableKeyProvider`); `KeypairGenerationJob`
  completes only on `worker` (its class comment). Web sees only public seams.

---

## The model

### Ownership: person-only keys
- **`EncryptedValue.owner` becomes `User`-only.** Drop the `Game` arm of the polymorphic
  owner. (Keep the column polymorphic in shape if simpler, but no `Game` may own a key —
  enforce in the model + a grep-proof; there are no rows to migrate.)
- Remove `Game#ai_key_present?` and `StoredKeySource#for_game`/game `decrypt_for` in their
  current "game owns a key" meaning; they're replaced by the pool below.

### The pool: people make keys available to a game
- New join **`GameKeyAuthorization`**: `belongs_to :game`, `belongs_to :user` (the key
  owner). Meaning: *"this person authorizes this game to spend their personal OpenRouter
  key."* Unique on `[game_id, user_id]`.
- **Anyone can offer** — GM or player. A member offers their **own** key (must have one:
  `user.ai_key_present?`); consent is the key owner's, always. Offer/revoke is a
  member-scoped action (a member may create/destroy only their **own** authorization).
- **Multiple coexist** — a game's available set is every authorization whose owner's key is
  present. There is no "active"/designated key; the set is unordered.
- **Any player may fund — this is intended, not incidental.** A scene summary (a game-level
  output) is paid by **whichever offered key wins the shuffle**, which may be any member's
  key — not specifically the GM's. This is a deliberate behavior change from the shipped
  path (`SceneSummaryService#api_key` currently resolves via the GM only): funding is
  drawn from the whole pool of consenting members, GM included but not privileged.

### Asset level decides whether the pool applies (recorded direction)
- **Every AI-generated asset records its LEVEL: `game` vs `personal`.**
  - **Game-level** (shared output — e.g. scene summary): eligible for **group
    contribution**, funded from the game's authorization pool (shuffle-and-pop above).
  - **Personal** (an individual's own output — e.g. a portrait a player generates for
    their own character, if scoped that way): funded by **that person's own key only**, not
    the pool.
- The level is a property of the **feature**, declared per feature as AI features land
  (#114 funding policy, #19 portraits, future). The resolver consults the pool **only for
  game-level** features; personal features resolve straight to the acting user's key.
- **In this card:** the only live feature is scene summary = **game-level**, so we build the
  pool path for it. But **do not hardcode "everything is game-level"** — leave the level as
  an explicit, declared property so a personal feature slots in without reshaping this.

### Per-key, per-game, per-feature contribution (SHIPS in this card)
- Contribution is **not** a bare on/off offer. A person manages **how each of their keys
  contributes**: *"this key funds summaries for game A; that key funds portraits for game B;
  this other key funds both for game C."*
- **Table shape (decided): one row per game×user×feature.** `GameKeyAuthorization` carries
  a `feature` column; **unique on `[game_id, user_id, feature]`**. "Summaries for game A"
  and "portraits for game A" are two rows. The per-feature pool query is a plain `where`,
  and each management-UI cell maps to one row's existence.
- **Management UI (SHIPS):** a person-side surface (Profile) showing the matrix of *their
  key × their games × fundable features*, toggling each cell (create/destroy the row).
  Person's side, because it's their money and their consent.

### Feature registry — `Ai::Feature` is the single source of truth (decided)
- New **`Ai::Feature`** registry: every AI feature declared once, with its `name`, `level`
  (`:game` / `:personal`), and whether it's **pool-fundable**. Canonical.
- **`AiUsage::FEATURES` derives from the registry** — the loose string list is replaced;
  `AiUsage` validates `feature` against the registry. `inbound_email` is declared as
  **app-infra** (not game/personal, not pool-fundable — app's own key, outside BYOK);
  `scene_summary` as **game-level**. One place defines every feature and its funding
  character; the resolver/pool consult it, `GameKeyAuthorization.feature` validates against
  it (fundable features only).

### The boundary — who does what (locked with owner)
- **Web app owns the pool.** The web tier is the system of record for *which* keys are
  available to a game: creating/revoking `GameKeyAuthorization`s and enumerating the
  available set (via the public presence seam `user.ai_key_present?` — web can read
  presence, never key material). **Web informs what is available to use; it never selects,
  decrypts, or spends.**
- **Worker owns the usage.** Only the worker can decrypt (`PrivateKey`), so the worker owns
  *using* a key: it takes the available pool the web app published, does the **random
  selection**, runs the **failover loop**, and makes the OpenRouter spend. This is not just
  a preference — the decryption credential only exists on `worker`, so usage structurally
  cannot happen anywhere else.

### Selection & failover (worker) — just shuffle the array and pop
- **`shuffle` the available authorizations once, then `pop`.** No exclusion set, no
  set-difference, no injectable RNG. Popping *is* the decrement: the failed key is gone
  because it was removed, and can't be redrawn because it's no longer in the array. The
  invariant (pool shrinks by one per failure, no key retried, ends empty) falls out of
  `pop` for free.

  ```ruby
  candidates = available_authorizations.shuffle
  loop do
    auth = candidates.pop or raise NoKeyAvailable   # empty → give up
    begin
      return generate_with(auth)                     # success ends it
    rescue KeyFundingError                            # 401/402/403/429 → next
      next
    end
    # any other error propagates and aborts — deliberately not rescued
  end
  ```

  - **Key-attributable failure** (invalid/auth 401/403, credit/quota 402, rate-limit 429)
    → `next` pops the next candidate.
  - **Any other failure** (content/prompt 400, network, 5xx) → not rescued, propagates,
    **aborts the whole run** (not the key's fault; don't walk the pool).
  - Empty array → `NoKeyAvailable` → `SceneSummaryService::ConfigurationError`, logged as
    today.
- **Testable without controlling randomness.** Tests stub *which* popped key fails and
  assert the array empties correctly (each key tried at most once, failed key never
  retried, exhaustion → `NoKeyAvailable`). The one-line `shuffle` needs no seam.
- **`AiKeyResolver`** stops being "pick one key string." It becomes the worker-side
  selector: it owns the shuffled candidate array and hands out the next popped candidate
  (owner + decrypted key), raising `NoKeyAvailable` when empty. The **try-next
  orchestration lives in the generation service** (`SceneSummaryService`), which classifies
  each OpenRouter error as "pop the next key" vs "abort." Crypto stays in the injected
  `Crypto::StoredKeySource`; the resolver stays decision-only.

---

## Files in the blast radius

**New**
- `app/models/game_key_authorization.rb` + `db/migrate/*_create_game_key_authorizations.rb`
- Member-scoped controller + routes to offer/revoke an authorization (own key only),
  surfaced in game settings UI (per `Games::SettingsController` + `GamePolicy` patterns).
- A ViewComponent for the game AI settings "keys available to this game" surface
  (per COMPONENT_CONVENTIONS — no bespoke markup).
- Specs + factory for the model, controller, component; policy for offer/revoke.

**Modified**
- `app/models/encrypted_value.rb` — `owner` User-only; forbid Game.
- `app/models/game.rb` — remove `ai_key_present?`; add `has_many :game_key_authorizations`
  and an "available key authorizations" query (present-key owners only).
- `app/services/crypto/stored_key_source.rb` — drop `for_game`; keep `for_user`.
- `app/services/ai_key_resolver.rb` — shuffle-once-then-pop selector over the game's
  available set; rewrite `spec/services/ai_key_resolver_spec.rb` (assert pop/exhaustion
  behavior, no RNG control needed).
- `app/services/scene_summary_service.rb` — the try-key → classify-error → next-key
  failover loop around the OpenRouter call; `spec/services/scene_summary_service_spec.rb`.
- `app/jobs/scene_summary_job.rb` if orchestration touches it.
- `sorbet/rbi/*` (`tapioca dsl` for new model), `.mutant.yml` (register new classes),
  `docs/ARCHITECTURE.md` + custody docs — "keys are person-owned; games use, never own;
  web publishes the available pool, worker selects and spends with random failover."

## Out of scope (build on this foundation later)
- Fizzy #114 funding policy/ledger and #19 portraits — both sit on top of the corrected
  ownership + pool model, not in this card.

## Settled scope
- **Feature-scoped contribution ships in THIS card** (owner decision) — the full model:
  a person authorizes each of their keys to fund specific **features** for specific
  **games**, plus the person-side management UI. Not a coarse per-game offer.
- **Table shape:** one `GameKeyAuthorization` row per `[game, user, feature]`.
- **`Ai::Feature` registry is canonical**; `AiUsage::FEATURES` derives from it.
- **Asset level** is a declared, explicit property per feature (`game` vs `personal`) —
  not hardcoded. Scene summary = game-level for this card; the resolver consults the pool
  only for game-level features.

## Open sub-decisions to confirm while implementing
- **Error classification source:** map OpenRouter/`ruby-openai` HTTP statuses (401/402/403/429
  → next key; else abort) — confirm the client surfaces status codes (`Faraday`/`OpenAI`
  error shape) so the classifier keys off status, not string matching. (context7 the
  `ruby-openai` error surface before relying on it.)
- **No RNG seam** — the selector is `shuffle` then `pop`. Tests drive *which* popped key
  fails and assert the array empties correctly; the one-line shuffle needs no control. (If
  a mutation ever survives *because* order is random, the assertion is wrongly about order —
  fix the assertion, don't add an RNG.)

## Verification
- `bundle exec rspec` green FIRST, then `bin/check-policy-consistency`,
  `bin/check-view-layering`, `bundle exec srb tc`, `bin/quality-metrics --check`,
  `bin/pre-push`.
- Grep-proof: no code path constructs a `Game`-owned `openrouter_key` `EncryptedValue`.
- Spec coverage of the **pool-decrement** matrix (order-agnostic): single available key
  (success; key-failure → set empty → NoKeyAvailable); two keys (first attempt key-fails →
  next draw excludes it → second succeeds); the failed key is never attempted twice in one
  resolution; non-key error aborts with the pool untouched (second key never tried); empty
  pool → NoKeyAvailable. Assertions are on *the available set shrinking / exhaustion*, not
  on which key was drawn first.
- Manual: two members of a game each offer their key; resolve a scene; confirm the summary
  is funded by one of the available keys, and (simulating a 402 on the first) that failover
  picks the second. A user's Profile BYOK setup is unchanged.
