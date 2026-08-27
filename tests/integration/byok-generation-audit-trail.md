# BYOK generation audit trail (`ai_generations`)

## What changed

Every BYOK-funded AI generation now writes a permanent audit row to the append-only
`ai_generations` table (`AiGeneration`), recording who requested the generation, whose
key paid for it, the model, token counts, and cost. The generated asset (`SceneSummary`)
keeps only provenance (`generated_at`) — accounting moved off the asset entirely.
`SceneSummaryJob` writes the summary and its audit row in one transaction via
`Ai::UserGeneration`, the shared engine every BYOK feature routes through.

## Setup

- A game with a GM and at least one player, `ai_summaries_enabled` on.
- A resolved scene in that game with a few posts.
- A user (GM or player) with a BYOK OpenRouter key authorized to fund `scene_summary`
  for the game (`GameKeyAuthorization`).

## Scenarios

### 1. Resolve with a funded key present
- As a user other than the key owner, resolve the scene (`PATCH .../resolve`).
- Expect the scene to show Resolved, and shortly after, the campaign-log summary to
  appear on the page via the broadcast (no reload needed).
- In a console, check the `ai_generations` row for that scene's summary
  (`asset_type: "SceneSummary"`, `asset_id: <summary.id>`):
  - `requested_by_id` is the resolving user.
  - `funded_by_id` is the key owner.
  - `model_used`, `input_tokens`, `output_tokens`, `cost` are populated.

### 2. Hand-edit the summary
- As the GM, edit the summary body.
- Expect the summary's `generated_at` to clear (provenance gone — it now reads as
  hand-authored) and `edited_at`/`edited_by` to be stamped.
- Expect the `ai_generations` row from Scenario 1 to be untouched — same row, same
  values, still present. It is a historical fact of the generation, independent of the
  asset's later edit.

### 3. No authorized key available
- Remove all `GameKeyAuthorization`s for `scene_summary` on the game (or use a game
  with none), then resolve a scene.
- Expect resolution to still succeed (notice: "Scene resolved.").
- Expect no summary to appear on the scene page.
- Expect no `ai_generations` row to be written.
- Expect an error log line from `SceneSummaryJob` referencing the exhausted key pool.
