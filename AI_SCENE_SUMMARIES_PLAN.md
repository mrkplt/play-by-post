# AI Scene Summaries — Feature Plan

## Overview

GMs can enable AI-generated narrative summaries of scenes per game. When a scene is
resolved and AI summaries are enabled, a background job calls OpenRouter to produce
in-character campaign-log prose. OOC posts are sent to the model labelled as such;
the model decides what is narratively relevant. Generated summaries can be manually
edited or deleted by the GM. The full corpus is readable as an HTML campaign log and
consumable as an RSS feed ordered by resolution time.

---

## Decisions

| Question | Decision |
|----------|----------|
| Private scenes in log / RSS | Never surfaced — inherit scene visibility |
| OOC post handling | Send all posts; label OOC posts `[OOC]`; model decides relevance |
| Generation trigger | Auto on scene resolution (if enabled); GM can edit or delete result |
| Summaries for unresolved scenes | Not supported — resolution is the trigger |
| Rate limiting regeneration | Not an app concern |
| Campaign log / RSS ordering | Chronological by `resolved_at` |
| AI provider | OpenRouter (OpenAI-compatible API) |
| RSS auth | Secret token in query string for members; public URL for public games |

---

## Proposed Data Model

### New table: `scene_summaries`

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `scene_id` | integer | FK → scenes, unique (one summary per scene) |
| `body` | text | Markdown prose |
| `ai_generated` | boolean | false if hand-written or manually overwritten |
| `model_used` | string | e.g. `openai/gpt-4o`, null if hand-written |
| `generated_at` | datetime | when the model produced this version (null if hand-written) |
| `edited_at` | datetime | last manual edit timestamp |
| `edited_by_id` | integer | FK → users, who last manually edited |
| `created_at` / `updated_at` | datetime | standard |

### Additions to `games`

| Column | Type | Default | Notes |
|--------|------|---------|-------|
| `ai_summaries_enabled` | boolean | false | GM toggles per game |

### New table: `rss_tokens`

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
  Builds the prompt from scene title, description, and all posts (labelling OOC),
  calls OpenRouter, returns the summary text. Stateless; injectable in tests.

### Job
- `app/jobs/scene_summary_job.rb`  
  Receives `scene_id`, calls `SceneSummaryService`, upserts `SceneSummary`.
  Enqueued automatically on scene resolution when `ai_summaries_enabled`.

### Controllers
- `app/controllers/scene_summaries_controller.rb`  
  Actions: `edit`, `update`, `destroy` (GM only).  
  Nested under `games/:game_id/scenes/:scene_id`.

- `app/controllers/campaign_logs_controller.rb`  
  Actions: `show` (HTML + RSS formats).  
  Nested under `games/:game_id`.  
  Scope: resolved, non-private scenes with summaries, ordered by `resolved_at`.  
  HTML: session auth. RSS: token param for members, no token required for public games.

### Presenters
- `app/presenters/scene_summary_presenter.rb`  
  `rendered_body` (Markdown → HTML), `status_label` ("AI-generated", "Edited",
  "Hand-written"), `formatted_generated_at`, `formatted_edited_at`.

### ViewComponents
- `app/components/shared/scene_summary_component.rb` + template  
  Displays summary body, status badge, edit/delete controls (GM only).

- `app/components/shared/campaign_log_entry_component.rb` + template  
  One entry in the campaign log: scene title, resolution date, summary prose, link to scene.

### Views / Templates
- `app/views/campaign_logs/show.html.erb` — campaign log page
- `app/views/campaign_logs/show.rss.builder` — RSS feed
- `app/views/scene_summaries/edit.html.erb` — GM edit form

---

## Route Changes

```ruby
resources :games do
  resource :campaign_log, only: [:show]   # GET /games/:id/campaign_log
                                           # GET /games/:id/campaign_log.rss?token=…

  resources :scenes do
    resource :scene_summary, only: [:edit, :update, :destroy]
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
{each post: "[OOC] Author: content" or "Author: content"}

Rules:
- Posts marked [OOC] are out-of-character. Include their content only when it
  directly shapes the fiction (e.g. a player describing their character's inner
  state). Ignore dice rolls, rule references, scheduling notes, and table talk.
- Write from an omniscient narrator perspective; do not invent events not present
  in the posts.
- Length: 150–400 words unless the scene warrants more.
```

---

## Files to Modify

| File | Change |
|------|--------|
| `app/models/scene.rb` | Add `has_one :scene_summary` |
| `app/models/game.rb` | Add `ai_summaries_enabled` boolean; `has_many :rss_tokens` |
| `app/controllers/scenes_controller.rb` | Enqueue `SceneSummaryJob` on `resolve` when AI enabled |
| `config/routes.rb` | Add `campaign_log` resource + `scene_summary` resource |
| `Gemfile` | Add `ruby-openai` (OpenAI-compatible client for OpenRouter) |
| `context/REQUIREMENTS.md` | Document new feature |
| `.mutant.yml` | Register new classes |
| `db/schema.rb` | Updated by migrations |

---

## Migrations

1. `AddAiSummariesEnabledToGames` — boolean column, default false
2. `CreateSceneSummaries` — new table with unique index on `scene_id`
3. `CreateRssTokens` — new table with unique index on `token`

---

## Quality Checklist

- [ ] Sorbet `# typed: true` on all new files; explicit `sig` on all methods called from templates
- [ ] Request specs: `spec/requests/scene_summaries_spec.rb`, `spec/requests/campaign_logs_spec.rb`
- [ ] Model specs: `spec/models/scene_summary_spec.rb`, `spec/models/rss_token_spec.rb`
- [ ] Service spec: `spec/services/scene_summary_service_spec.rb` (stub OpenRouter)
- [ ] Job spec: `spec/jobs/scene_summary_job_spec.rb`
- [ ] Component specs: `spec/components/shared/scene_summary_component_spec.rb`, `spec/components/shared/campaign_log_entry_component_spec.rb`
- [ ] Presenter spec: `spec/presenters/scene_summary_presenter_spec.rb`
- [ ] Register all new classes in `.mutant.yml`
- [ ] `bin/pre-push` passes before each push

---

## Implementation Order

1. Migrations + model shells (`SceneSummary`, `RssToken`)
2. `SceneSummaryService` + tests (stub OpenRouter)
3. `SceneSummaryJob` + tests
4. Wire job into `scenes#resolve`
5. `SceneSummariesController` (edit/update/destroy) + request specs
6. Presenter + ViewComponents for summary display
7. Surface summary on `scenes#show`
8. `CampaignLogsController` + HTML campaign log page
9. RSS feed format + token auth
10. Game settings UI to toggle `ai_summaries_enabled` + RSS token management
11. `REQUIREMENTS.md` update
12. Full `bin/pre-push` run

---

## Risks & Notes

- **OpenRouter API key** needs to be added to Railway environment variables and `.env`
  locally. The service should raise a clear configuration error if absent.
- **Token count:** Very long scenes (hundreds of posts) may approach model context limits.
  The service should log a warning and truncate oldest posts first if needed (follow-on).
- **Upsert idempotency:** The job uses upsert on `scene_id` so re-resolution or
  re-enqueueing never creates duplicate summaries.
- **RSS caching:** The feed should set `Cache-Control` headers; Solid Cache can serve
  repeated polls without a DB hit.
- **Token revocation:** GMs should be able to regenerate a member's RSS token (e.g. if
  they shared the URL inadvertently). A simple destroy+create on `RssToken` suffices.
