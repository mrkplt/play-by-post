# AI Usage Tracking — Future Feature Note

## Idea

As more features use AI (scene summaries, potentially inbound email processing, etc.),
we will want a single place to record usage data rather than scattering columns across
feature tables.

## Proposed: `ai_usages` table

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `feature` | string | e.g. `"scene_summary"`, `"inbound_email"` — identifies the calling feature |
| `model_used` | string | e.g. `openai/gpt-4o` |
| `input_tokens` | integer | prompt token count |
| `output_tokens` | integer | completion token count |
| `created_at` | datetime | when the API call was made |

## Relationship

`AiUsage` is a standalone append-only log. Features write a record after each API
call; nothing references back to the source row. Aggregation and reporting are done
with queries on this table.

## Bridging from scene_summaries

`scene_summaries` currently carries `model_used`, `input_tokens`, and `output_tokens`
directly as a pragmatic starting point. When this table is introduced, migrate that
data into `ai_usages` and remove the columns from `scene_summaries`.

## Scope of tracking

- Scene summary generation
- Inbound email AI processing (if added)
- Any future AI-assisted feature

## Not in scope (yet)

- Cost calculation (token costs vary by model and change over time — keep that in a
  reporting layer, not the DB)
- Per-user or per-game aggregation (derive from queries on this table)
