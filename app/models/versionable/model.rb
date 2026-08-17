# typed: true

# Change-history snapshotting: every save writes a full copy of the record's
# versioned fields to a per-model versions table, with attribution. Character is
# the original adopter; Page adopts it too (title + body).
#
# Snapshotting is an explicit consequence of saving rather than an after_save
# callback, so the behaviour is readable at the definition instead of in a
# callback chain — and the repo's callback ratchet (bin/check-callbacks) is
# migrating *off* callbacks. save/save! are the only paths that need overriding:
# create and update route through save, create!/update! through save!, and
# touch/update_column bypass both — exactly as after_save did. super is wrapped
# in the transaction so a failed snapshot still rolls the record back.
#
# Deliberately a plain module the model `include`s, not an
# ActiveSupport::Concern (bin/check-concerns). Each adopter supplies the two
# things that differ: `versions` (the has_many the snapshot is created through)
# and `version_attributes` (which fields constitute a version, plus attribution).
module Versionable
  module Model
    extend T::Sig
    extend T::Helpers

    abstract!

    # The includer is an ActiveRecord model, so `transaction` and the version
    # association resolve without a per-method bind.
    requires_ancestor { ActiveRecord::Base }

    # The has_many association the snapshot rows are written to (e.g.
    # character_versions). Declared by the adopter so the module stays agnostic
    # about the table name.
    sig { abstract.returns(T.untyped) }
    def versions; end

    # The version row this record's current state should produce. Pure — the
    # snapshot writes exactly what this returns, so attribution can be tested
    # without saving anything. Adopters typically fall back from Current.user to
    # the record's owner for edited_by.
    sig { abstract.returns(T::Hash[Symbol, T.untyped]) }
    def version_attributes; end

    # Attribution derived from the version history, for read surfaces (the /api
    # payloads). The creator is the editor of the first version and is immutable
    # — later versions never change it; the last editor is the editor of the most
    # recent version. Both read the ordered `versions` association, so an adopter
    # that eager-loads versions pays no extra query.
    sig { returns(T.nilable(Integer)) }
    def created_by_id
      versions.order(:created_at).first&.edited_by_id
    end

    sig { returns(T.nilable(Integer)) }
    def last_edited_by_id
      versions.order(:created_at).last&.edited_by_id
    end

    sig { params(options: T.untyped).returns(T.untyped) }
    def save(**options)
      transaction { super.tap { |saved| snapshot_version if saved } }
    end

    sig { params(options: T.untyped).returns(T.untyped) }
    def save!(**options)
      transaction { super.tap { snapshot_version } }
    end

    private

    sig { void }
    def snapshot_version
      versions.create!(version_attributes)
    end
  end
end
