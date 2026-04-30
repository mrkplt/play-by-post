# typed: true

class AiUsage < ApplicationRecord
  extend T::Sig

  FEATURES = T.let(%w[inbound_email scene_summary].freeze, T::Array[String])

  validates :feature,    presence: true, inclusion: { in: FEATURES }
  validates :model_used, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord }

  scope :for_feature, ->(feature) { where(feature: feature) }
end
