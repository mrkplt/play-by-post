# typed: strict

class NotificationMailer < ApplicationMailer
  extend T::Sig

  sig { params(scene: Scene, recipient: User).returns(Mail::Message) }
  def new_scene(scene, recipient)
    game = T.must(scene.game)
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))
    @scene_notification = T.let(scene_notification(scene, game), T.nilable(SceneNotificationPresenter))

    mail(
      to: recipient.email,
      reply_to: scene_reply_to(scene),
      subject: "[#{game.name}] New scene: #{scene.title}"
    )
  end

  sig { params(scene: Scene, recipient: User).returns(Mail::Message) }
  def scene_resolved(scene, recipient)
    game = T.must(scene.game)
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))
    @scene_notification = T.let(scene_notification(scene, game), T.nilable(SceneNotificationPresenter))

    mail(
      to: recipient.email,
      subject: "[#{game.name}] Scene resolved: #{scene.title}"
    )
  end

  sig { params(scene: Scene, recipient: User, posts: T::Array[Post]).returns(Mail::Message) }
  def post_digest(scene, recipient, posts)
    game = T.must(scene.game)
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))
    @scene_notification = T.let(
      scene_notification(
        scene, game,
        post_presenters: posts.first(10).map { |post| PostPresenter.new(post) },
        extra_count: [ posts.size - 10, 0 ].max
      ),
      T.nilable(SceneNotificationPresenter)
    )

    mail(
      to: recipient.email,
      reply_to: scene_reply_to(scene),
      subject: "[#{game.name}] Activity in: #{scene.title}"
    )
  end

  private

  # The scene wrapped for an email template: display values plus the two URLs
  # every notification links to.
  sig do
    params(scene: Scene, game: Game, extra: T.untyped).returns(SceneNotificationPresenter)
  end
  def scene_notification(scene, game, **extra)
    SceneNotificationPresenter.new(
      ScenePresenter.new(scene),
      scene_url: game_scene_url(game, scene),
      mute_url: toggle_notification_preference_game_scene_url(game, scene),
      **extra
    )
  end

  sig { params(scene: Scene).returns(String) }
  def scene_reply_to(scene)
    domain = Rails.application.credentials.resend_inbound_domain ||
             Rails.application.config.action_mailer.default_url_options[:host]
    "scene-#{scene.id}@#{domain}"
  end
end
