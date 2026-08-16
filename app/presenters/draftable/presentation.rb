# typed: true

# The presenter-layer half of drafting: the draft predicate and the
# player-facing affordances that follow from it. Included by the presenters for
# Post, Page and SceneSummary so each renders "draft" consistently.
#
# A draft is not yet visible to the people who read the published record, so a
# presenter exposes `draft?` (the raw state), a `draft_status_label` for a
# badge, and `hidden_from_players?` — the flag a component uses to show the
# "only you can see this until you publish" affordance.
#
# Deliberately a plain module the presenter `include`s, not an
# ActiveSupport::Concern — `bin/check-concerns` enforces that. The including
# presenter is a BasePresenter (a SimpleDelegator around the model), so `draft`
# delegates straight through.
module Draftable
  module Presentation
    extend T::Sig

    DRAFT_LABEL = "Draft"
    PUBLISHED_LABEL = "Published"

    sig { returns(T::Boolean) }
    def draft?
      draftable_model.draft?
    end

    # The badge text for this record's draft state.
    sig { returns(String) }
    def draft_status_label
      draft? ? DRAFT_LABEL : PUBLISHED_LABEL
    end

    # Whether the record is invisible to the audience that reads the published
    # version — true exactly while it is still a draft. Drives the "only you can
    # see this until you publish" affordance.
    sig { returns(T::Boolean) }
    def hidden_from_players?
      draft?
    end

    private

    # The underlying model, which carries Draftable::Model. The includer is a
    # BasePresenter (a SimpleDelegator), so the model is its delegation target;
    # read it through __getobj__ rather than assuming an ivar name.
    sig { returns(Draftable::Model) }
    def draftable_model
      T.cast(T.cast(self, SimpleDelegator).__getobj__, Draftable::Model)
    end
  end
end
