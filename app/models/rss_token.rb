# typed: true

class RssToken < ApplicationRecord
  extend T::Sig

  belongs_to :user

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  sig { void }
  def regenerate!
    update!(token: self.class.generate_secure_token)
  end

  sig { returns(String) }
  def self.generate_secure_token
    SecureRandom.hex(32)
  end

  private

  sig { void }
  def generate_token
    self.token = self.class.generate_secure_token if token.blank?
  end
end
