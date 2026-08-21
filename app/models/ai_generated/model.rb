# typed: true

# The shared AI-provenance behaviour a record gains once it carries the
# provenance columns (`generated_at`, `model_used`, `input_tokens`,
# `output_tokens`, `generated_by_id`, `cost`, `edited_at`): the
# `ai_generated?`/`edited?` predicates and the "a hand-edit supersedes AI
# generation" transition. First adopted by SceneSummary; Character Portraits is
# the next AI-producible asset expected to include it.
#
# Provenance is a fact stored ON the asset — uniform across every
# AI-producible model — not tracked in a side table. A record is
# "AI-generated" exactly when `generated_at` is present; a person editing the
# body by hand supersedes that fact, so `#apply_manual_edit` clears every
# provenance column alongside stamping the edit.
#
# Deliberately a plain module the model `include`s, not an
# ActiveSupport::Concern — `bin/check-concerns` enforces that. Only genuinely
# shared *behaviour* lives here; the provenance columns themselves are declared
# per-model (each model's own migration/schema/RBI), same as Draftable::Model
# leaves the `draft` column and its scopes to the includer.
module AiGenerated
  module Model
    extend T::Sig

    # The includer is an ActiveRecord model carrying the provenance columns
    # above, read/written through the AR attribute accessors Sorbet sees via
    # each model's own tapioca RBI.
    sig { returns(T::Boolean) }
    def ai_generated?
      T.unsafe(self).generated_at.present?
    end

    sig { returns(T::Boolean) }
    def edited?
      T.unsafe(self).edited_at.present?
    end

    # A person editing the body by hand supersedes any AI generation — clears
    # generated_at/model_used/token counts/generated_by/cost so #ai_generated?
    # and the "edited" byline read correctly afterward, alongside the new body
    # and editor.
    sig { params(body: T.nilable(String), editor: User).returns(T::Boolean) }
    def apply_manual_edit(body:, editor:)
      T.unsafe(self).update(
        body: body, edited_by: editor, edited_at: Time.current,
        generated_at: nil, model_used: nil, input_tokens: nil, output_tokens: nil,
        generated_by_id: nil, cost: nil
      )
    end
  end
end
