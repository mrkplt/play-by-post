# typed: true

# The drafts-controller machinery shared by every boolean-on-row draftable
# record: autosaving the draft flag and publishing it. Included by
# Pages::DraftsController and SceneSummaries::DraftsController — each a namespaced
# drafts controller within its record's own domain.
#
# This is the controller-layer half of the Draftable concern, alongside
# Draftable::Model (draft?/publish!) and Draftable::Presentation (the badge).
# Post is deliberately NOT an adopter: a post draft is a separate row managed by
# PostDraft (distinct row per (user, scene), discarded rather than published),
# mechanics that do not generalize to a flag on a single row.
#
# A plain module included directly, not an ActiveSupport::Concern
# (`bin/check-concerns`). `requires_ancestor` lets Sorbet resolve the controller
# methods without a per-method bind. The including controller supplies the four
# things that differ via the private hooks below; `save`/`publish` are shared.
module Draftable
  module Controller
    extend T::Sig
    extend T::Helpers
    abstract!

    requires_ancestor { ApplicationController }

    # Autosave: write the submitted attributes onto the record as a draft. JSON,
    # so the editor's autosave loop can fire silently.
    #
    # This is a helper, not the Rails action — the including controller defines a
    # one-line `save` action that delegates here. Mutant cannot measure a mutated
    # *action* method inserted through a module (its undef/reinsert cycle does not
    # round-trip cleanly through `include`), but it measures this helper normally,
    # exactly as it does the other controller mixins in this app.
    sig { void }
    def draftable_save
      record = draftable_record
      authorize record, :manage?

      if record.update(draftable_params.to_h.merge(draft: true))
        render json: { id: record.to_param }, status: :ok
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_content
      end
    end

    # Promote the draft to published and return to the record. A helper for the
    # same reason as #draftable_save — the controller's `publish` action delegates
    # here.
    sig { void }
    def draftable_publish
      record = draftable_record
      authorize record, :publish?
      record.publish!
      redirect_to draftable_published_path(record), notice: draftable_published_notice
    end

    private

    # The record being drafted/published — the including controller resolves it
    # from params within its own domain.
    sig { abstract.returns(T.untyped) }
    def draftable_record; end

    # The strong params permitted on autosave (the record's editable fields).
    sig { abstract.returns(ActionController::Parameters) }
    def draftable_params; end

    # Where publishing redirects — the record's own screen.
    sig { abstract.params(_record: T.untyped).returns(String) }
    def draftable_published_path(_record); end

    # The flash notice shown after publishing.
    sig { abstract.returns(String) }
    def draftable_published_notice; end
  end
end
