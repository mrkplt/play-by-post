# Plan: AI Character Portrait Generation (Fizzy #19)

A player generates an AI **portrait image** for their own character (single game) from a
text prompt, via an OpenRouter image model, **funded from the game's contribution pool**
(any member of the game who authorized their BYOK key for this feature). The image lands
in the character's existing portrait library alongside uploads. This is a new
**`game`-level (pool-fundable)** `Ai::Feature`, funded exactly like scene summaries.

The original card described *prose analysis of posts + an eulogy*; that framing is
**superseded** (recorded on the card). This is image generation, no post analysis, no eulogy.

---

## 1. What already exists (reuse, don't rebuild)

Grounded in the current tree:

- **`CharacterImage`** (`app/models/character_image.rb`) — one image in a character's
  portrait library; `include UploadedImage::Model` supplies the attachment, validations,
  variants, and `make_current!` exclusivity. Today the only creation path is player upload.
- **`CharacterImagesController`** + `ImageLibrary` concern + `CharacterPortraitLibraryPresenter`
  + `Shared::ImageLibraryComponent` — the portrait library UI on `characters/show`,
  authorized by **`CharacterImagePolicy#manage?` (owning player only — the GM does not
  curate a player's portraits)**. This is exactly our trigger authority.
- **`Ai::Feature`** (`app/models/ai/feature.rb`) — the AI-feature registry. It declares three
  levels (`game`/`personal`/`app_infra`), but **`:personal` is unused speculation for #19**.
  Since any game member's key may fund a portrait, `character_portrait` is a **`game`-level**
  (pool-fundable) feature, same category as `scene_summary` — and `:personal` should be
  **deleted** (see §3). The only meaningful distinction left is pool-fundable BYOK vs.
  app-key infrastructure.
- **`Ai::UserGeneration`** (`app/services/ai/user_generation.rb`) — the engine every
  BYOK-funded generation routes through; returns a `Result` carrying `funded_by` so the
  caller writes the audit row. Built around `Ai::Funding` → the *game pool*
  (`GameKeyAuthorization`). **This is exactly our funding path — reuse it unchanged.**
- **`AiKeyResolver` / `Ai::Funding`** — pool selection (shuffle) + failover across the game's
  authorized keys. **Reused as-is** — a portrait generation pops candidates and fails over
  just like a scene summary. No new funding class needed.
- **`GameKeyAuthorization`** (`app/models/game_key_authorization.rb`) — one member's consent
  that their key may fund one pool-fundable feature for one game; `available_for(game:,
  feature:)` is the pool. It `validates :feature, inclusion: { in:
  Ai::Feature.pool_fundable_names }`, so registering `character_portrait` as `game`-level is
  precisely what lets members authorize it and the pool fund it.
- **`AiGeneration`** (audit row) + **`AiUsage`** — permanent per-generation audit; validates
  `feature` against the registry. `asset_type`/`asset_id` already generic (scene summary uses
  `"SceneSummary"`); ours will be `"CharacterImage"`.
- **`SceneSummaryJob`** — the async generate → persist-in-one-transaction → broadcast pattern
  to mirror.
- **`Crypto::StoredKeySource`** (worker-only) — decrypts a user's `openrouter_key`.
- **R2 storage** (`config/storage.yml`, `cloudflare_r2`) — Active Storage service the
  generated PNG attaches to, same as an upload.
- **Game ↔ Page** — `Game has_many :pages`. The GM's designated environment/setting Page is
  a `Page` reference on the game (new column).

**Net:** the *storage, library UI, audit, BYOK-decryption, AND funding* halves all exist —
funding is the existing pool path, reused unchanged. The new work is: registering a
`game`-level feature, an **image-generation call** (chat → images endpoint), the
**prompt composition** (GM env Page + player prompt + safety system prompt), the **safety
pipeline**, the **game-settings env-Page picker**, and the **generate affordance** on the
character sheet.

Members authorize their key for portraits through the **existing contribution-management
matrix** — `character_portrait` becomes a new pool-fundable column there automatically,
because that UI is driven by `Ai::Feature.pool_fundable` (verify the matrix renders the new
column; it should require no bespoke work).

---

## 2. OpenRouter image generation (researched)

`Ai::UserGeneration` today calls `client.chat(...)` (text). Image generation is a **different
endpoint**:

- **Request:** `POST https://openrouter.ai/api/v1/images`, `Authorization: Bearer <key>`,
  body `{ "model": <slug>, "prompt": <text> }`.
- **Response:** `{ "data": [ { "b64_json": "<base64 PNG>", "media_type": "image/png" } ],
  "usage": { "cost": <float> } }`. Image bytes at `data[0].b64_json`, base64-decode before
  attaching.
- **Model:** configurable via env (mirror `OPENROUTER_MODEL`), new key
  `OPENROUTER_IMAGE_MODEL`, default a mainstream model. **Choose a provider/model that
  carries provider-side moderation** (e.g. `openai/gpt-image-1`, which enforces OpenAI's own
  policy server-side) as the first line of defense — see §4. Record the concrete default in
  `docs/CONFIGURATION.md`.
- The `ruby-openai` client (`OpenAI::Client`) used today targets chat; confirm whether its
  version exposes an images method against a custom `uri_base`, else issue the POST with
  `Faraday` directly (the funding layer already rescues `Faraday::Error`). **Decision: use a
  small dedicated `Ai::ImageRequest` object that does the Faraday POST and parses the
  response**, rather than bending `UserGeneration` (which is chat-response-shaped: it parses
  `choices[].message.content`). Keep the two generation shapes as separate objects.

---

## 3. Funding — the game pool (reuse the existing path)

Portraits fund from the **game's contribution pool**: any member who authorized their BYOK
key for this feature may fund a generation, with the existing shuffle + failover. This is the
**same path scene summaries use** — no new funding class.

- **Register the feature** as game-level: add
  `new(name: "character_portrait", level: :game, label: "Character portraits")` to
  `Ai::Feature::REGISTRY`. Because `pool_fundable? == game_level?`, this immediately makes it
  authorizable (`GameKeyAuthorization` accepts it) and pool-fundable
  (`AiKeyResolver#candidates` / `Ai::Funding` fund it).
- **Generate** through the existing engine:
  `Ai::UserGeneration.new(feature: "character_portrait", game:).call(...)` — except the call
  is an *image* request, not chat (see §2). Concretely: `Ai::Funding` yields each pooled key
  to a block, and the block runs the **image** request instead of a chat completion. So the
  reuse is of `Ai::Funding` (pool + failover) with an image-shaped block; `Ai::UserGeneration`
  itself is chat-response-shaped, so the portrait job composes `Ai::Funding` directly (or a
  thin `Ai::ImageGeneration` sibling of `UserGeneration` that parses the images response).
- **Audit:** the `Spend` returns `funded_by` = whichever pooled member's key won the failover
  walk. The `AiGeneration` row records `requested_by` (the player who clicked) **and**
  `funded_by` (the pool member who paid) — these now legitimately differ, exactly like a
  scene summary funded by another member.
- `AiUsage::FEATURES` / `AiGeneration` accept `character_portrait` automatically (derived from
  the registry).
- **`Ai::Funding::Exhausted`** propagates when the game has no working authorized key — the
  job rescues it and broadcasts a "no funding available" failure (same handling as
  `SceneSummaryJob`).

**Delete the `:personal` level.** It was declared in `LEVELS` (with a `personal_level?`
predicate and a docstring paragraph) purely as speculation for #19 — no feature ever used it,
and #19 turned out to be game-level. With portraits pool-funded, the only real distinction is
**pool-fundable BYOK (`:game`) vs. app-key infrastructure (`:app_infra`)**; `:personal` is
dead weight. Per the repo's no-dead-code rule, remove it in this card:
- drop `:personal` from `LEVELS`, delete `personal_level?`;
- rewrite the docstring's three-level explanation to two levels;
- delete the `feature_spec.rb` `personal_level?` example (and drop "personal" from the
  app-infra example's wording).
This is in-scope cleanup the task touches — not a follow-up.

---

## 4. Safety: preventing pornographic & CSAM output

**Owner decisions (revised):**
1. **Moderation is a pre-generation text screen via OpenAI's Moderation API**
   (`omni-moderation-latest`, free) — `Ai::Moderation`. The full composed prompt (safety
   preamble + environment + player text) is screened BEFORE a pool key is spent; a flagged
   verdict **blocks** generation. This is provider moderation (OpenAI's classifier), not a
   self-maintained deny-list, and it gives granular per-category control. Funded by the app
   key (app-infra), not a game/BYOK feature.
2. **Text pre-gen only — the generated image is NOT screened.** omni-moderation's
   `sexual/minors` category is text-only, so the text screen is where that signal is
   available anyway. The accepted gap: an image the model produces that passes the text
   screen and the image model's own moderation is not independently checked here — the weekly
   R2 sampling job (Fizzy #144) is the backstop for that gap.
3. **No punitive lock, no placeholder.** A moderation flag (or an image-model refusal) simply
   **blocks**: nothing is generated, nothing persisted, a plain error toast + a logged reason
   (with the flagged categories and the prompt parts). There is no "pervert" image, no
   `portrait_locked`, no lock-guarding of upload/make-current.

Plus the injection-resistant safety system prompt, unchanged.

The controls:

1. **Injection-resistant safety system prompt** — a fixed, non-user-editable preamble
   prepended to every image prompt. It (a) states the image depicts an adult fantasy/RPG
   character, with **no sexual content, no nudity, no pornography, and absolutely no sexual or
   suggestive depiction of minors / childlike figures**, and (b) **resists prompt injection**:
   the player-supplied text and the GM env-Page text are framed explicitly as *untrusted
   character description to render*, never as instructions that can override the rules, reveal
   the prompt, or change the rules. Lives in one constant (`Ai::PortraitSafetyPrompt`),
   unit-tested. (`Ai::PortraitSafetyPrompt` implemented.)

2. **Pre-generation moderation — a Rule pipeline** (`Ai::Moderation`). It posts the composed
   prompt to OpenAI's Moderation API (`omni-moderation-latest`) for the raw signal, then hands
   `(prompt, result)` to every `Ai::Moderation::Rule` subclass. **The rules ARE the enforcement**
   (they replace an inline flagged-category check): each rule independently enforces one policy
   and returns an `Outcome` (`moderated?` + `reason`); `Ai::Moderation` runs them all and
   `.any?`-s — if any moderates, the `Verdict` is flagged and carries every failing reason for
   the alert + the user notice. Rules are discovered via `Rule.descendants` at runtime (the app
   is eager-loaded) and are **injectable** so specs drive the aggregation with fakes. Adding a
   rule is adding a subclass — no registry.
   - `Rule` is abstract (`abstract!`, a raising `moderate`) with `block`/`allow` Outcome
     builders. Shipped rules: `Rules::FlaggedCategories` (blocks on any OpenAI-flagged category)
     and `Rules::MinorSafety` (zero-tolerance: any non-zero `sexual/minors` score blocks, stricter
     than OpenAI's own flag).
   - The job screens BEFORE spending a key and **blocks on flagged**. **Fails closed**: an
     unparseable API response yields an empty result to the rules; a transport error is not
     swallowed (propagates, the job blocks). Endpoint/auth is a configurable seam
     (`DEFAULT_URL`, app key), stubbed in tests via Faraday's test adapter. (Implemented.)

3. **Image-model refusal** — if the image model still refuses at generation time
   (`Ai::ImageRequest::Refused`), that is also a plain block (no image, error toast + log),
   not a punitive consequence.

4. **Provenance & audit** — every *successful* generation writes an `AiGeneration` row
   (requested_by, funded_by, model, cost, asset). A blocked/moderated attempt writes no spend
   row (nothing was generated); the block is logged with the flagged categories and the
   prompt parts.

### 4a. Consequence of a block (owner decision — revised)

There is **no punitive lock and no placeholder**. A moderation flag, or an image-model
refusal, simply **blocks**: nothing is generated, nothing persisted, the character's portrait
is unchanged. The player gets a plain error toast; the operator gets a log line with the
flagged categories (moderation) and the game/player prompt parts. The `portrait_locked`
column and the static "pervert" asset from the earlier design are **removed** — they were
built and then dropped by owner decision; the not-yet-deployed migration was rewritten out.

Other failures — empty pool (`Ai::Funding::Exhausted`), network error — get the same benign
error toast and change nothing.

---

## 5. GM environment/setting Page (game settings)

- **Migration:** add `environment_page_id` (nullable FK → `pages`) to `games`.
- **Model:** `Game belongs_to :environment_page, class_name: "Page", optional: true`; validate
  the page belongs to this game.
- **Settings UI:** in game settings, a picker (select of this game's pages) to designate the
  environment/setting Page. GM-only (existing game-settings authorization).
- **Use:** its markdown body becomes the *setting* portion of the composed image prompt. Nil
  is allowed — then only the safety prompt + player prompt compose.

---

## 6. Prompt composition

`Ai::PortraitPrompt` (pure, unit-tested) composes, in order:
1. `Ai::PortraitSafetyPrompt` (fixed, non-editable) — §4.1, including the injection-resistance
   framing that marks everything after it as untrusted character description.
2. The GM's `environment_page.body` if designated (setting/environment), else nothing.
3. The **player's own prompt** (the markdown they wrote).

Output is a single prompt string for the image request. The safety preamble is always first
and always present. `Ai::PortraitPrompt` also exposes the two source parts separately
(`game_part`, `player_part`) so the refusal logger (§4a.4) can record each alongside the full
composed string.

---

## 7. The generate flow (skeleton-first, frame-poll delivery)

The delivery is modelled on the **BYOK keypair** flow (poll, not broadcast) because a job
cannot build Active Storage variant URLs outside a request context. The record is created
first as a **skeleton**, and the job fills it in.

**The skeleton (`CharacterImage` generation state):** a `CharacterImage` can exist before its
file arrives. New columns: `generated_at` (AI provenance via `AiGenerated::Model`, stamped on
completion), `failed_at` + `failure_reason` (a failed attempt). States: no file & not failed
= **pending**; file attached = **ready** (a real portrait); `failed_at` set = **failed** (a
short-lived carrier for the player-facing reason). The `acceptable_image` validation is now
**conditional** (`if: file_attached?`), so a fileless skeleton is valid. The library lists
only `ready` rows (`scope :ready` = `joins(:file_attachment)`).

1. **Trigger:** the `Shared::PortraitGeneratorComponent` on `characters/show`, for the owner
   (`CharacterImagePolicy#manage?`) — a **markdown** prompt field. It has three states in its
   own stable target: idle (form), pending (spinner + the `portrait-poll` Stimulus controller),
   failed (reason + form to retry).
2. **`CharacterPortraitGenerationsController` (nested singleton resource):**
   - `#create` — authorize `:manage?`, create the pending skeleton, enqueue
     `CharacterPortraitJob(image_id, requester_id, prompt)`, render the control's pending state.
   - `#show` — the **poll target**. The `portrait-poll` controller GETs it (`Accept:
     text/vnd.turbo-stream.html`) on an interval and applies the returned stream via
     `Turbo.renderStreamMessage`. Still pending → replace the control with the spinner again
     (poll continues). Settled → replace the control (idle) **+** refresh the library div
     (`image_library_character_image`) **+** a completion/failure toast; a failed skeleton's
     reason is read once and the dead row destroyed (`consume_failure_reason!`). The stream
     building lives in `CharacterPortraitStreamsPresenter` (keeps the controller thin).
3. **`CharacterPortraitJob` → `CharacterPortraitGeneration`** (the pipeline, off the queue):
   - Compose the prompt (`Ai::PortraitPrompt`).
   - **Moderate first:** `Ai::Moderation.new(api_key: app_key).call(composed)`. If flagged,
     `image.fail_generation!(reason)` and log the categories + prompt parts — **no key spent**.
   - `Ai::Funding.new(resolver:, feature: "character_portrait", game:).call { |key|
     Ai::ImageRequest.new(model:, prompt:).call(key) }` — the game-pool path with failover.
   - **On success:** in one transaction `image.complete_generation!(png)` (attach the PNG +
     stamp `generated_at`) and write the `AiGeneration` audit row (`asset_type:
     "CharacterImage"`, `requested_by` = player, `funded_by` = pooled payer, may differ). Not
     made current — the player picks it.
   - **On `Ai::ImageRequest::Refused`, `Ai::Funding::Exhausted`, or a network failure:**
     `image.fail_generation!` with a generic reason, persist nothing else. (No lock.)
4. **`Ai::ImageRequest` refusal detection (resolved).** OpenRouter signals a content-moderation
   block as an **HTTP 400** whose `error.code` is `content_policy_violation` (input/output
   flagged) or `refusal` (the model explicitly refused), with the reasons in `error.metadata`.
   Faraday's `raise_error` turns the 400 into a `Faraday::Error`; `Ai::ImageRequest` inspects
   its response body (parsing the raw JSON — the json middleware doesn't run on the error
   path) and raises `Refused` (carrying the metadata reasons) for those codes, re-raising any
   other Faraday error so a key-attributable status still fails over in `Ai::Funding`. The
   detection is confined to `#refusal_for`.

### Configuration (resolved)

- **Model names AND the moderation endpoint are required env vars — no default, raise if
  absent** (owner decision): `OPENROUTER_MODEL` (summarization), `OPENROUTER_IMAGE_MODEL`
  (portraits), `OPENAI_MODERATION_MODEL` and `OPENAI_MODERATION_URL` (moderation). `ENV.fetch`
  with no default, so a missing var fails loudly rather than using a stale model/endpoint. The
  test env sets placeholders in `config/environments/test.rb`.
- **Keys are encrypted credentials, not env vars.** The moderation call is OpenAI's
  `/v1/moderations` (a distinct provider from OpenRouter), so it needs an **OpenAI key**:
  `credentials.openai.api_key` (nested under `openai:` in `production.yml.enc`), separate from
  the existing `credentials.openrouter_api_key`. Documented in `docs/CONFIGURATION.md`.

---

## 8. Testing plan (write first — `tests/integration/character-portraits.md` + specs)

Per the workflow, the `tests/integration/` markdown plan is committed with the work.

- **`Ai::Feature`**: `character_portrait` registered as `game`-level, `game_level?` and
  `pool_fundable?` true, appears in `pool_fundable_names`; `GameKeyAuthorization` **accepts**
  it (a member can authorize it for a game).
- **Funding via the pool**: `AiKeyResolver#candidates(feature: "character_portrait", game:)`
  returns the game's authorized members; `Ai::Funding` fails over across them; `funded_by` is
  the winning member and may differ from `requested_by`; `Exhausted` when the pool is empty.
- **`Ai::PortraitSafetyPrompt` / `Ai::PortraitPrompt`**: safety preamble always first and
  present; the injection-resistance framing is included; env-page body included when
  designated, omitted (and no crash) when nil; player prompt last; `game_part`/`player_part`
  exposed for the refusal logger.
- **`Ai::ImageRequest`**: parses `data[0].b64_json` + `usage.cost`; a `Faraday` key-failure
  status flows to `Ai::Funding` failover; a response with no data is handled. The
  provider-refusal → `Refused` mapping is the **stubbed seam** — spec it against a placeholder
  refusal shape now; the real OpenRouter shape is a later localized change here only. Job/lock/
  placeholder specs stub `Ai::ImageRequest` to raise `Refused` directly, so they never depend
  on the wire shape.
- **`Ai::Moderation`**: posts the composed prompt with the app bearer key; unflagged verdict
  passes; flagged verdict carries the violated category names; fails closed on an unparseable
  response; a transport error propagates (real #connection driven via the test adapter).
- **`CharacterPortraitJob` — moderation blocks first**: a flagged verdict blocks BEFORE any key
  spend (no `Ai::Funding` call, no `AiGeneration` row, no `CharacterImage`), logs the categories
  + prompt parts, broadcasts a benign toast.
- **`CharacterPortraitJob` — success** (moderation passes): creates a `CharacterImage` with an
  attached file + an `AiGeneration` row (`requested_by` = clicker, `funded_by` = pooled payer,
  may differ), does **not** make it current.
- **`CharacterPortraitJob` — Refused / Exhausted / network failure**: persists nothing, benign
  failure toast. Restore `ActiveJob::Base.queue_adapter` in `around`/`ensure`.
- **Contribution matrix**: `character_portrait` renders as a new pool-fundable column;
  authorizing/deauthorizing a key for it works.
- **Policy / request specs**: only the owning player can trigger (`manage?`); GM and other
  players are denied. In-place (Turbo Stream) response, not a redirect (except auth denial).
- **Game env-Page**: migration + `belongs_to :environment_page`; settings picker lists only
  this game's pages; GM-only.
- **Component/presenter**: the generate affordance renders for the owner only; new
  component/presenter added to `.mutant.yml`.
- **Feature spec**: both viewports (1024px breakpoint) — the generate form and the in-place
  library update.
- Every new class gets a direct spec (`bin/check-test-presence`); kill survivors to hold the
  83% mutation floor.

---

## 9. Resolved decisions (owner)

1. **Moderation:** OpenAI Moderation API (`omni-moderation-latest`, free) as a **pre-generation
   text screen** on the composed prompt (`Ai::Moderation`), plus the injection-resistant safety
   system prompt. **Text pre-gen only** — the image output is not screened (that gap is the
   weekly R2 sampling job, Fizzy #144). No self-maintained deny-list/quarantine.
2. **Image model:** model-agnostic via `OPENROUTER_IMAGE_MODEL` (env). Not a build blocker.
3. **Player prompt field:** **markdown** (toolbar + preview).
4. **On a block (moderation flag or image-model refusal):** simply block — nothing generated,
   nothing persisted, benign error toast + a logged reason (categories + prompt parts). **No
   punitive lock, no placeholder** — `portrait_locked` and the "pervert" asset are removed.

---

## 10. Migration/cleanup notes

- New feature only — no old path to delete. Funding reuses the existing game-pool path, so
  no new funding class. No compatibility shims.
- **Remove the dead `:personal` level** from `Ai::Feature` (LEVELS, `personal_level?`,
  docstring) and its spec example — no feature uses it and portraits are game-level. See §3.
- **No `portrait_locked`, no placeholder asset** — removed by owner decision (§4a). The
  not-yet-deployed migration that added the column was rewritten out.
- Add every new component/presenter to `.mutant.yml`; `# typed: true` sigil on every new/
  touched `app/`/`lib/` file; `sig` on any method a template calls.
- `docs/CONFIGURATION.md`: `OPENROUTER_IMAGE_MODEL`. `docs/ARCHITECTURE.md`: the image-
  generation path (pool-funded, image endpoint) + the safety approach (provider moderation +
  injection-resistant prompt + the refusal consequence in §4a).
- Gem maintenance already done on this branch (bundle update committed).

---

## Sources (research)

- OpenRouter image generation — endpoint/request/response shape:
  https://openrouter.ai/blog/tutorials/image-generation/ ,
  https://openrouter.ai/docs/docs/overview/multimodal/image-generation
- CSAM prevention (layered controls, human review, reporting): OpenAI CSAM guidance;
  Thorn *Safety by Design* (info.thorn.org); NCMEC CyberTipline.
- Filtering-alone is insufficient against *novel* AI-generated CSAM:
  https://arxiv.org/pdf/2512.05707 , https://techxplore.com/news/2026-07-dataset-filtering-limited-csam-generation.html
