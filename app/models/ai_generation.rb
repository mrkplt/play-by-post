# typed: true

# The permanent audit trail for every BYOK-funded AI generation: who requested
# it, whose key paid, cost, model, tokens, and which asset it produced. Rows
# are inserted once by the generation pipeline (Ai::Funding et al.) and never
# touched again.
#
# Deliberately carries NO belongs_to associations. requested_by_id,
# funded_by_id, asset_type, and asset_id are recorded historical facts, not
# live references — no association means no dependent-destroy cascade can
# ever reach an audit row. The row outlives its asset and its users by
# design: deleting a User or a SceneSummary must never delete or orphan the
# fact that a generation happened.
#
# asset_type/asset_id are a plain string+integer pair, not a Rails
# polymorphic association, for the same reason: a polymorphic belongs_to
# still resolves and can still be swept up by association-aware code. Callers
# that need the current asset look it up themselves
# (asset_type.constantize.find_by(id: asset_id)) and must handle it being
# gone.
class AiGeneration < ApplicationRecord
  extend T::Sig

  validates :feature,         presence: true, inclusion: { in: Ai::Feature.names }
  validates :model_used,      presence: true
  validates :requested_by_id, presence: true
  validates :funded_by_id,    presence: true
  validates :asset_type,      presence: true
  validates :asset_id,        presence: true

  # Audit rows are append-only and permanent — never updated, never deleted,
  # by any path. Marking a persisted row readonly makes ActiveRecord raise
  # ReadOnlyRecord on BOTH update and destroy, in-band and visible here rather
  # than behind before_update/before_destroy callbacks (bin/check-callbacks).
  # A new (not-yet-persisted) row must remain writable so the initial insert
  # succeeds.
  sig { returns(T::Boolean) }
  def readonly?
    persisted?
  end
end
