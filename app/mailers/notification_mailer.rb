# typed: strict

class NotificationMailer < ApplicationMailer
  extend T::Sig

  # A scene notification's recipient, paired with the scene it concerns — the
  # two values every notification method needs together to build its
  # SceneNotificationPresenter and headers.
  class Delivery < T::Struct
    const :scene, Scene
    const :recipient, User
  end

  sig { params(delivery: Delivery).returns(Mail::Message) }
  def new_scene(delivery)
    scene = delivery.scene
    game = T.must(scene.game)
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))
    @scene_notification = T.let(scene_notification(scene, game), T.nilable(SceneNotificationPresenter))

    mail(
      to: delivery.recipient.email,
      reply_to: scene_reply_to(scene),
      subject: "[#{game.name}] New scene: #{scene.title}"
    )
  end

  sig { params(delivery: Delivery).returns(Mail::Message) }
  def scene_resolved(delivery)
    scene = delivery.scene
    game = T.must(scene.game)
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))
    @scene_notification = T.let(scene_notification(scene, game), T.nilable(SceneNotificationPresenter))

    mail(
      to: delivery.recipient.email,
      subject: "[#{game.name}] Scene resolved: #{scene.title}"
    )
  end

  sig { params(delivery: Delivery, posts: T::Array[Post]).returns(Mail::Message) }
  def post_digest(delivery, posts)
    scene = delivery.scene
    game = T.must(scene.game)
    @game_presenter = T.let(GamePresenter.new(game), T.nilable(GamePresenter))
    @scene_notification = T.let(
      scene_notification(scene, game, **post_digest_extra(posts)),
      T.nilable(SceneNotificationPresenter)
    )

    mail(
      to: delivery.recipient.email,
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

  # The digest's post_presenters/extra_count pair: the first 10 posts
  # presented in full, plus how many more are not shown.
  sig { params(posts: T::Array[Post]).returns(T::Hash[Symbol, T.untyped]) }
  def post_digest_extra(posts)
    {
      post_presenters: posts.first(10).map { |post| PostPresenter.new(post) },
      extra_count: [ posts.size - 10, 0 ].max
    }
  end

  sig { params(scene: Scene).returns(String) }
  def scene_reply_to(scene)
    application = Rails.application
    domain = application.credentials.resend_inbound_domain ||
             application.config.action_mailer.default_url_options[:host]
    "scene-#{scene.id}@#{domain}"
  end
end
