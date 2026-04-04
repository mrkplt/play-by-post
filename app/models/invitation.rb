# typed: true

class Invitation < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :invited_by, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :pending, -> { where(accepted_at: nil) }

  sig { returns(T::Boolean) }
  def accepted?
    accepted_at.present?
  end

  sig { void }
  def accept!
    update!(accepted_at: Time.current)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end
end
