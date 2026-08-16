# typed: true

# The shared drafting behaviour a record gains once it has a `draft` boolean
# column: the `draft?`/`published?` predicates and `publish!`. Included by Post,
# Page and SceneSummary.
#
# A draft is a plain boolean on the row. Per the owner decision, editing a
# published record never pulls the published text away — the live version stays
# live while the author edits — so there is no shadow copy or separate draft
# row. `draft` therefore only ever guards a record that has never been
# published; once published, edits are immediately live.
#
# Deliberately a plain module the model `include`s, not an
# ActiveSupport::Concern — `bin/check-concerns` enforces that. Only genuinely
# shared *behaviour* lives here. The `published`/`drafts` scopes and the
# presence-unless-draft validation stay declared on each model, where the
# wiring is visible and statically typed rather than installed by a macro.
module Draftable
  module Model
    extend T::Sig

    # The includer is an ActiveRecord model carrying the `draft` boolean column.
    # The column reader is per-model (each model's tapioca RBI declares it), so
    # it is read through `draft_value`; `update!` is typed via the cast in
    # `record`.
    sig { returns(T::Boolean) }
    def draft?
      draft_value
    end

    sig { returns(T::Boolean) }
    def published?
      !draft_value
    end

    # Promote a draft to published in place — the same row, no copy. Idempotent:
    # publishing an already-published record is a no-op update.
    sig { void }
    def publish!
      record.update!(draft: false)
    end

    private

    sig { returns(T::Boolean) }
    def draft_value
      T.unsafe(self).draft
    end

    sig { returns(ActiveRecord::Base) }
    def record
      T.cast(self, ActiveRecord::Base)
    end
  end
end
