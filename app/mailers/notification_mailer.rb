class NotificationMailer < ApplicationMailer
  def new_scene(scene, recipient)
    @scene = scene
    @game = scene.game
    @recipient = recipient
    @scene_url = game_scene_url(@game, @scene)
    @mute_url = toggle_notification_preference_game_scene_url(@game, @scene)

    mail(
      to: recipient.email,
      reply_to: scene_reply_to(@scene),
      subject: "[#{@game.name}] New scene: #{@scene.title}"
    )
  end

  def scene_resolved(scene, recipient)
    @scene = scene
    @game = scene.game
    @recipient = recipient
    @scene_url = game_scene_url(@game, @scene)

    mail(
      to: recipient.email,
      subject: "[#{@game.name}] Scene resolved: #{@scene.title}"
    )
  end

  def post_digest(scene, recipient, posts)
    @scene = scene
    @game = scene.game
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

  def scene_reply_to(scene)
    domain = ENV.fetch("MAILGUN_DOMAIN", "example.com")
    "scene-#{scene.id}@inbound.#{domain}"
  end
end
