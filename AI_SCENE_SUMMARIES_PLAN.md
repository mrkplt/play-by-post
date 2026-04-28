# AI Scene Summaries — Feature Plan

## Overview

GMs and players generate narrative summaries of scenes using Claude. Summaries are
in-character prose (campaign log style), ignoring game-mechanics OOC content unless
it meaningfully shapes the fiction. The summary corpus is readable as a campaign log
and consumable as an RSS feed. GMs can edit any summary and can toggle AI generation
on or off per game.

---

## Open Questions (discuss before building)

1. **Private scenes in campaign log / RSS?**  
   Private scenes are invisible to players. Should their summaries ever appear in
   the log or feed? Simplest default: no — a summary inherits the visibility rules
   of its scene. Worth confirming.

2. **RSS authentication model.**  
   RSS readers typically can't do session auth. Options:
   - **Token URL** — generate a per-user secret token embedded in the feed URL
     (e.g. `/games/:id/feed.rss?token=abc123`). Easy to share, easy to revoke.
   - **Public feed for public games, gated for private games** — simpler but all-or-nothing.
   - **No RSS for private games** — easiest to implement, most limiting.  
   Recommendation: token URL, one token per game member, rotatable.

3. **OOC post handling.**  
   Posts already carry `is_ooc: true`. Two strategies:
   - **Pre-filter:** Strip all OOC posts before sending to Claude. Clean, cheap,
     but loses context the AI might use to understand what "actually happened."
   - **Label and let Claude decide:** Send all posts, marking OOC ones, and instruct
     Claude to include OOC content only where it shapes the fiction. More nuanced,
     slightly more tokens.  
   Recommendation: label-and-decide — closer to what you described.

4. **When does generation trigger?**  
   - Auto-generate when a scene is marked `resolved` (if AI enabled for the game)?
   - Manual "Generate summary" button only?
   - Both (auto on resolve + on-demand button)?  
   Recommendation: auto on resolve + manual regenerate button. Keeps the log
   complete without GM overhead.

5. **Ongoing (unresolved) scene summaries.**  
   Should GMs be able to generate a summary before a scene resolves? Useful for
   long-running games. Recommend: yes, on demand, with a visual indicator that the
   scene is still in progress.

6. **Cost exposure / rate limiting.**  
   The Claude API costs money per call. Considerations:
   - Rate-limit regeneration (e.g. once per 5 minutes per scene).
   - Track which model and approximate token count per summary for transparency.
   - AI generation off by default per game (GM opts in).

7. **Campaign log ordering.**  
   Scenes have a tree structure (parent/child). Ordering options:
   - Flat list by `created_at` (simplest).
   - Flat list by `resolved_at` (matches narrative completion).
   - Tree-aware (parent before children, depth-first).  
   Recommendation: flat by `created_at` for v1, with tree-aware as a follow-on.

8. **Claude model choice.**  
   Haiku 4.5 is fastest/cheapest; Sonnet 4.6 produces richer prose. Recommend
   Sonnet 4.6 for summaries — this is narrative quality work — with the model
   recorded per summary so we can upgrade without ambiguity about historical output.

---

## Proposed Data Model

### New table: `scene_summaries`

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `scene_id` | integer | FK → scenes, unique (one summary per scene) |
| `body` | text | Markdown prose |
| `ai_generated` | boolean | false if hand-written or manually edited after generation |
| `model_used` | string | e.g. `claude-sonnet-4-6`, null if hand-written |
| `generated_at` | datetime | when the AI produced this version (null if hand-written) |
| `edited_at` | datetime | last manual edit timestamp |
| `edited_by_id` | integer | FK → users, who last manually edited |
| `created_at` / `updated_at` | datetime | standard |

### Additions to `games`

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `ai_summaries_enabled` | boolean | false | GM toggles per game |

### New table: `rss_tokens` (if token-URL approach chosen)

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `game_id` | integer | FK → games |
| `user_id` | integer | FK → users |
| `token` | string | unique, random 32-char hex |
| `created_at` / `updated_at` | datetime | |

---

## Domain Model

```
Game (ai_summaries_enabled)
  └─ Scene
       └─ SceneSummary (body, ai_generated, model_used, …)
  └─ RssToken → User
```

---

## New Files

### Models
- `app/models/scene_summary.rb` — `belongs_to :scene`, `belongs_to :edited_by, class_name: "User", optional: true`
- `app/models/rss_token.rb` — `belongs_to :game`, `belongs_to :user`

### Service
- `app/services/scene_summary_service.rb`  
  Builds the Claude prompt from scene title, description, and posts (labelling OOC),
  calls the Anthropic API, returns the summary text. Stateless; callable from the
  job and from tests.

### Job
- `app/jobs/scene_summary_job.rb`  
  Receives `scene_id`, calls `SceneSummaryService`, creates/updates `SceneSummary`.
  Enqueued on scene resolution (if AI enabled) and on manual regenerate requests.

### Controllers
- `app/controllers/scene_summaries_controller.rb`  
  Actions: `edit`, `update` (GM edits body), `regenerate` (enqueues job, GM only).  
  Nested under `games/:game_id/scenes/:scene_id`.

- `app/controllers/campaign_logs_controller.rb`  
  Actions: `index` (HTML + RSS formats).  
  Nested under `games/:game_id`.  
  Scope: resolved scenes with summaries (+ optionally in-progress).  
  RSS requires token param (or session auth for HTML).

### Presenters
- `app/presenters/scene_summary_presenter.rb`  
  `rendered_body` (Markdown → HTML), `status_label` ("AI-generated", "Edited",
  "Hand-written"), `formatted_generated_at`, `formatted_edited_at`.

### ViewComponents
- `app/components/shared/scene_summary_component.rb` + template  
  Displays summary body, status badge, edit/regenerate controls (GM only).

- `app/components/shared/campaign_log_entry_component.rb` + template  
  One entry in the campaign log: scene title, date, summary prose, link to scene.

### Views / Templates
- `app/views/campaign_logs/index.html.erb` — campaign log page
- `app/views/campaign_logs/index.rss.builder` — RSS feed
- `app/views/scene_summaries/edit.html.erb` — edit form

### Mailer (optional, follow-on)
- Could email the summary to participants when generated, similar to existing digest.

---

## Route Changes

```ruby
resources :games do
  resource :campaign_log, only: [:show]   # GET /games/:id/campaign_log
                                           # GET /games/:id/campaign_log.rss

  resources :scenes do
    resource :scene_summary, only: [:edit, :update] do
      post :regenerate, on: :member
    end
  end
end
```

---

## AI Prompt Design (sketch)

```
You are a campaign chronicler for a tabletop RPG. Write a narrative summary of
the following scene as it would appear in a campaign log — vivid, in-character
prose, past tense, no game-mechanics language.

Scene title: {title}
Scene description: {description}

Posts (in chronological order):
{posts, each prefixed with author name and [OOC] tag where is_ooc=true}

Rules:
- Include [OOC] content only when it directly shapes the fiction (e.g. a player
  describing their character's internal state). Ignore dice rolls, rule references,
  table talk, or scheduling notes.
- Write from an omniscient narrator perspective; do not invent events not present
  in the posts.
- Length: 150–400 words unless the scene warrants more.
```

---

## Files to Modify

| File | Change |
|------|--------|
| `app/models/scene.rb` | Add `has_one :scene_summary` |
| `app/models/game.rb` | Add `ai_summaries_enabled` boolean; add `has_many :rss_tokens` |
| `app/controllers/scenes_controller.rb` | Enqueue `SceneSummaryJob` on `resolve` action when AI enabled |
| `config/routes.rb` | Add campaign_log resource + scene_summary resource |
| `Gemfile` | Add `anthropic` (Anthropic Ruby SDK) |
| `context/REQUIREMENTS.md` | Document new feature |
| `.mutant.yml` | Register new classes |
| `db/schema.rb` | Updated by migrations |

---

## Migrations

1. `AddAiSummariesEnabledToGames` — add boolean column, default false
2. `CreateSceneSummaries` — new table
3. `CreateRssTokens` — new table (if token-URL RSS approach chosen)

---

## Quality Checklist

- [ ] Sorbet `# typed: true` on all new files; explicit `sig` on all methods called from templates
- [ ] Request specs: `spec/requests/scene_summaries_spec.rb`, `spec/requests/campaign_logs_spec.rb`
- [ ] Model specs: `spec/models/scene_summary_spec.rb`
- [ ] Service spec: `spec/services/scene_summary_service_spec.rb` (stub Anthropic API)
- [ ] Job spec: `spec/jobs/scene_summary_job_spec.rb`
- [ ] Component spec: `spec/components/shared/scene_summary_component_spec.rb`
- [ ] Presenter spec: `spec/presenters/scene_summary_presenter_spec.rb`
- [ ] Register all new classes in `.mutant.yml`
- [ ] `bin/pre-push` passes before each push

---

## Implementation Order

1. Migrations + model shell (`SceneSummary`, `RssToken`)
2. `SceneSummaryService` + tests (stubbed Anthropic)
3. `SceneSummaryJob` + tests
4. Wire job into `scenes#resolve`
5. `SceneSummariesController` (edit/update/regenerate) + request specs
6. Presenter + ViewComponent for summary display
7. Surface summary on `scenes#show`
8. `CampaignLogsController` + HTML campaign log page
9. RSS feed format + token auth
10. Game settings UI to toggle `ai_summaries_enabled`
11. `REQUIREMENTS.md` update
12. Full `bin/pre-push` run

---

## Risks & Notes

- **Anthropic API key** needs to be added to Railway environment variables and to
  `.env` locally. The service should raise a clear error if the key is absent.
- **Token count:** Very long scenes (hundreds of posts) may approach context limits.
  The service should truncate or summarise in chunks if needed (follow-on concern).
- **Regeneration idempotency:** The job should upsert the summary, not create
  duplicates. The `scene_id` unique index on `scene_summaries` enforces this.
- **RSS caching:** The feed should set appropriate cache headers; Solid Cache can
  serve it without hitting the DB on every poll.
