class SceneMailbox < ApplicationMailbox
  before_processing :find_scene
  before_processing :require_participant

  def process
    raw_body = mail.decoded.to_s.strip
    content = EmailContentExtractor.new(raw_body).extract.strip

    return if content.blank?

    scene.posts.create!(
      user: sender_user,
      content: content,
      is_ooc: false
    )
  end

  private

  def scene
    @scene
  end

  def find_scene
    scene_id = mail.to.first.match(/\Ascene-(\d+)@/i)&.captures&.first
    @scene = Scene.find_by(id: scene_id)
    bounce_with NotFoundBounce.new(inbound_email) unless @scene
  end

  def sender_user
    @sender_user ||= User.find_by(email: mail.from.first)
  end

  def require_participant
    user = sender_user
    unless user && @scene.participant?(user)
      bounce_with UnauthorizedBounce.new(inbound_email)
    end
  end

  class NotFoundBounce
    def initialize(inbound_email) = @inbound_email = inbound_email
    def call = @inbound_email.bounced!
  end

  class UnauthorizedBounce
    def initialize(inbound_email) = @inbound_email = inbound_email
    def call = @inbound_email.bounced!
  end
end
