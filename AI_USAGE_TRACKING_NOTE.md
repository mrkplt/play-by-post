# AI Usage Tracking

## Current state

One feature currently uses AI: inbound email processing via `EmailContentExtractor`, which
calls OpenRouter (Gemma 3.4B-IT free model) to strip quoted text and signatures from
email replies before creating posts. Token/model data returned in the API response is
currently discarded.

Scene summaries are **not yet implemented** (design doc only). There is nothing to migrate.

---

## Goal

A single append-only `ai_usages` table to record every AI API call across all features.
Written once, never updated. Aggregation and reporting are done with queries on this table.

---

## `ai_usages` table

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | integer | PK | |
| `feature` | string | NOT NULL | e.g. `"inbound_email"`, `"scene_summary"` |
| `model_used` | string | NOT NULL | e.g. `"google/gemma-3-4b-it:free"` |
| `input_tokens` | integer | nullable | prompt tokens; nil if API does not return them |
| `output_tokens` | integer | nullable | completion tokens; nil if API does not return them |
| `created_at` | datetime | NOT NULL | when the API call completed |

No `updated_at` — records are never modified.

---

## Implementation plan

### 1. Migration

```ruby
# db/migrate/<timestamp>_create_ai_usages.rb
class CreateAiUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usages do |t|
      t.string  :feature,      null: false
      t.string  :model_used,   null: false
      t.integer :input_tokens
      t.integer :output_tokens
      t.datetime :created_at,  null: false
    end

    add_index :ai_usages, :feature
    add_index :ai_usages, :created_at
  end
end
```

No `updated_at`. The `created_at` column is explicit (not via `t.timestamps`) to avoid
Rails auto-managing a column we don't want.

### 2. Model — `app/models/ai_usage.rb`

```ruby
# typed: true

class AiUsage < ApplicationRecord
  extend T::Sig

  FEATURES = T.let(%w[inbound_email scene_summary].freeze, T::Array[String])

  validates :feature,    presence: true, inclusion: { in: FEATURES }
  validates :model_used, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord }

  scope :for_feature, ->(f) { where(feature: f) }
end
```

`before_update` guard enforces append-only at the model layer.

### 3. Update `EmailContentExtractor`

The OpenRouter response (OpenAI-compatible) already contains `usage.prompt_tokens`,
`usage.completion_tokens`, and `model`. Currently `make_request` returns the full parsed
hash but `extract` only digs for the content string and discards everything else.

**Changes required:**

- `make_request` stays as-is (returns the full response hash).
- `extract` should capture token counts and model from the response, then call
  `AiUsage.create!` after a successful extraction.
- Write the record only on a successful API call (non-fallback path). Do not write
  records when falling back to raw body — those calls either failed or were skipped.
- Wrap the `AiUsage.create!` in a `rescue` so a DB write failure never breaks email
  processing.

Sketch:

```ruby
sig { returns(String) }
def extract
  api_key = Rails.application.credentials.openrouter_api_key
  return @raw_body if api_key.blank?

  response = make_request(api_key)
  content  = response.dig("choices", 0, "message", "content").presence

  if content
    record_usage(response)
    content
  else
    @raw_body
  end
rescue StandardError
  @raw_body
end

private

sig { params(response: T::Hash[String, T.untyped]).void }
def record_usage(response)
  usage = response["usage"] || {}
  AiUsage.create!(
    feature:       "inbound_email",
    model_used:    response.fetch("model", MODEL),
    input_tokens:  usage["prompt_tokens"],
    output_tokens: usage["completion_tokens"]
  )
rescue StandardError => e
  Rails.logger.error("AiUsage write failed: #{e.message}")
end
```

### 4. Sorbet

- `app/models/ai_usage.rb` — `# typed: true` sigil; sigs on any methods added beyond
  validations/scopes (Rails DSL does not need explicit sigs).
- `EmailContentExtractor` already has `# typed: strict`; add sig for `record_usage`.
- Run `bundle exec tapioca dsl` after adding the model to regenerate RBIs if needed.

### 5. Tests

**`spec/models/ai_usage_spec.rb`**
- Valid factory creates successfully.
- Validates presence of `feature` and `model_used`.
- Rejects `feature` values not in `FEATURES`.
- `before_update` raises `ActiveRecord::ReadOnlyRecord`.
- `for_feature` scope filters correctly.

**`spec/services/email_content_extractor_spec.rb`** — add cases:
- Successful API call creates one `AiUsage` record with correct `feature`, `model_used`,
  `input_tokens`, `output_tokens`.
- Fallback (blank API key, network error, blank content) does NOT create an `AiUsage`
  record.
- `AiUsage.create!` failure is swallowed — extracted content is still returned.

### 6. Factory — `spec/factories/ai_usages.rb`

```ruby
FactoryBot.define do
  factory :ai_usage do
    feature      { "inbound_email" }
    model_used   { "google/gemma-3-4b-it:free" }
    input_tokens { 120 }
    output_tokens { 40 }
    created_at   { Time.current }
  end
end
```

### 7. Register in `.mutant.yml`

Add `AiUsage` to `matcher.subjects`.

---

## Adding future AI features

When scene summaries (or any new AI feature) are implemented:

1. Add the feature string to `AiUsage::FEATURES`.
2. Call `AiUsage.create!` (with the same rescue pattern) after each successful API call.
3. Add the new feature string to the factory's enum list and extend the model spec.

---

## Not in scope

- Cost calculation — token prices vary by model and change over time; keep in reporting layer.
- Per-user or per-game aggregation — derive from queries on this table.
- Association back to source rows (scene, inbound email, etc.) — not needed; `feature` +
  `created_at` is sufficient for audit/reporting.
