# typed: true

class NotificationMailer < ApplicationMailer
  extend T::Sig

  sig { params(scene: Scene, recipient: User).returns(Mail::Message) }
  def new_scene(scene, recipient)
    @scene = scene
    @game = T.must(scene.game)
    @recipient = recipient
    @scene_url = game_scene_url(@game, @scene)
    @mute_url = toggle_notification_preference_game_scene_url(@game, @scene)

    mail(
      to: recipient.email,
      reply_to: scene_reply_to(@scene),
      subject: "[#{@game.name}] New scene: #{@scene.title}"
    )
  end

  sig { params(scene: Scene, recipient: User).returns(Mail::Message) }
  def scene_resolved(scene, recipient)
    @scene = scene
    @game = T.must(scene.game)
    @recipient = recipient
    @scene_url = game_scene_url(@game, @scene)

    mail(
      to: recipient.email,
      subject: "[#{@game.name}] Scene resolved: #{@scene.title}"
    )
  end

  sig { params(scene: Scene, recipient: User, posts: T::Array[Post]).returns(Mail::Message) }
  def post_digest(scene, recipient, posts)
    @scene = scene
    @game = T.must(scene.game)
    @recipient = recipient
    @posts = posts.first(10)
    @extra_count = [ posts.size - 10, 0 ].max
    @scene_url = game_scene_url(@game, @scene)
    @mute_url = toggle_notification_preference_game_scene_url(@game, @scene)

    mail(
      to: recipient.email,
      reply_to: scene_reply_to(@scene),
      subject: "[#{@game.name}] Activity in: #{@scene.title}"
    )
  end

  private

  sig { params(scene: Scene).returns(String) }
  def scene_reply_to(scene)
    domain = Rails.application.credentials.mailgun_domain
    "scene-#{scene.id}@inbound.#{domain}"
  end
end
