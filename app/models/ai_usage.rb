# typed: true

class AiUsage < ApplicationRecord
  extend T::Sig

  FEATURES = T.let(%w[inbound_email scene_summary].freeze, T::Array[String])

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
