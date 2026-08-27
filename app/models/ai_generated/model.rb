# typed: true

# The shared AI-provenance behaviour a record gains once it carries the
# provenance column (`generated_at`) and an `edited_at`: the
# `ai_generated?`/`edited?` predicates and the "a hand-edit supersedes AI
# generation" transition. First adopted by SceneSummary; Character Portraits is
# the next AI-producible asset expected to include it.
#
# Provenance is the fact that an asset is AI-generated — a fact stored ON the
# asset, uniform across every AI-producible model, not tracked in a side
# table. It is determined by `generated_at` ALONE: a record is "AI-generated"
# exactly when `generated_at` is present, and a person editing the body by
# hand supersedes that fact, so `#apply_manual_edit` clears `generated_at`
# alongside stamping the edit.
#
# Accounting — who requested the generation, whose key paid, cost, model, and
# token counts — is NOT provenance and does not live on the asset. It is
# recorded once, permanently, in the append-only `AiGeneration` audit trail
# (see app/models/ai_generation.rb) at generation time, and never touched
# again. The on-asset principle for provenance is unchanged by that split;
# only its column list narrows to `generated_at`.
#
# Deliberately a plain module the model `include`s, not an
# ActiveSupport::Concern — `bin/check-concerns` enforces that. Only genuinely
# shared *behaviour* lives here; the provenance column itself is declared
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
    # generated_at so #ai_generated? and the "edited" byline read correctly
    # afterward, alongside the new body and editor. Any AiGeneration audit row
    # already recorded for this asset is untouched: it is a permanent record
    # of the generation that happened, independent of whether the asset was
    # later hand-edited.
    sig { params(body: T.nilable(String), editor: User).returns(T::Boolean) }
    def apply_manual_edit(body:, editor:)
      T.unsafe(self).update(
        body: body, edited_by: editor, edited_at: Time.current,
        generated_at: nil
      )
    end
  end
end
