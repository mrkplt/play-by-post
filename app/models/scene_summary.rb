# typed: true

class SceneSummary < ApplicationRecord
  extend T::Sig

  belongs_to :scene
  belongs_to :edited_by, class_name: "User", optional: true

  validates :body, presence: true

  sig { returns(T::Boolean) }
  def ai_generated?
    generated_at.present?
  end

  sig { returns(T::Boolean) }
  def edited?
    edited_at.present?
  end
end
