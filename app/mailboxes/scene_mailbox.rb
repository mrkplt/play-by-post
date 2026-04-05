# typed: true

class SceneMailbox < ApplicationMailbox
  extend T::Sig

  before_processing :find_scene
  before_processing :require_participant

  sig { void }
  def process
    raw_body = mail.decoded.to_s.strip
    content = EmailContentExtractor.new(raw_body).extract.strip

    return if content.blank?

    T.must(scene).posts.create!(
      user: T.must(sender_user),
      content: content,
      is_ooc: false
    )
  end

  private

  sig { returns(T.nilable(Scene)) }
  def scene
    @scene
  end

  sig { void }
  def find_scene
    scene_id = mail.to.first.match(/\Ascene-(\d+)@/i)&.captures&.first
    @scene = Scene.find_by(id: scene_id)
    inbound_email.bounced! unless @scene
  end

  sig { returns(T.nilable(User)) }
  def sender_user
    @sender_user ||= User.find_by(email: mail.from.first)
  end

  sig { void }
  def require_participant
    user = sender_user
    inbound_email.bounced! unless user && T.must(@scene).participant?(user)
  end
end
