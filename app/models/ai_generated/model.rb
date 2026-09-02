# typed: true

# The shared AI-provenance behaviour a record gains once it carries the
# provenance column (`generated_at`) and an `edited_at`: the
# `ai_generated?`/`edited?` predicates and the hand-edit transition. First
# adopted by SceneSummary; Character Portraits is the next AI-producible asset
# expected to include it.
#
# Provenance is the fact that an asset is AI-generated — a fact stored ON the
# asset, uniform across every AI-producible model, not tracked in a side
# table. It is determined by `generated_at` ALONE: a record is "AI-generated"
# exactly when `generated_at` is present.
#
# The flag is STICKY (Fizzy #122): once a record has been AI-generated, a later
# hand-edit does NOT clear it — the asset stays AI-generated, because an
# AI-authored draft that a human then polishes is still AI-authored in
# substance. `#apply_manual_edit` therefore leaves `generated_at` intact and
# only stamps the edit. The one reset — emptying the body ("unless all text was
# deleted") — is enforced by the adopter at its save boundary (see
# SceneSummary#reset_provenance_if_blank), so it holds for every write path, not
# just the hand-edit action.
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

    # A hand-edit stamps the new body, editor, and edit time but leaves
    # generated_at intact — the AI-generated flag is sticky (see the class
    # comment): a human polishing an AI-authored asset does not erase that it was
    # AI-authored. Emptying the body, however, resets provenance: an asset with
    # no text starts fresh. The AiGeneration audit row (if any) is untouched
    # regardless — it is a permanent record of the generation that happened.
    sig { params(body: T.nilable(String), editor: User).returns(T::Boolean) }
    def apply_manual_edit(body:, editor:)
      # generated_at is intentionally NOT cleared here — the flag is sticky. The
      # only reset (emptying the body) is enforced uniformly at the adopter's
      # save boundary, so it applies to every write path, not just this action.
      T.unsafe(self).update(body: body, edited_by: editor, edited_at: Time.current)
    end
  end
end
