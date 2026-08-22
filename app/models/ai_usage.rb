# typed: true

class AiUsage < ApplicationRecord
  extend T::Sig

  # Derived from the canonical Ai::Feature registry — the one place every AI
  # feature is declared. AiUsage records spend for any feature (including
  # app-infra like inbound_email), so it validates against the full registry,
  # not just the pool-fundable subset.
  FEATURES = T.let(Ai::Feature.names.freeze, T::Array[String])

  validates :feature,    presence: true, inclusion: { in: FEATURES }
  validates :model_used, presence: true

  scope :for_feature, ->(feature) { where(feature: feature) }

  # Usage rows are write-once: inserted, never updated. Marking a persisted row
  # readonly makes ActiveRecord raise ReadOnlyRecord on any update, in-band and
  # visible here rather than behind a before_update callback (bin/check-callbacks).
  # A new (not-yet-persisted) row must remain writable so the initial insert
  # succeeds.
  sig { returns(T::Boolean) }
  def readonly?
    persisted?
  end
end
