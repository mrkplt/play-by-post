# typed: strict

class Shared::PostItemComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      post: PostPresenter,
      game: Game,
      current_user: User,
      scene: T.nilable(Scene),
      read_post_ids: T.nilable(T::Set[Integer])
    ).void
  end
  def initialize(post:, game:, current_user:, scene: nil, read_post_ids: nil)
    @post = post
    @game = game
    @current_user = current_user
    @scene = scene
    @read_post_ids = read_post_ids
  end

  sig { returns(T::Boolean) }
  def unread?
    return false if @read_post_ids.nil?
    return false if @scene&.resolved?
    return false unless @post.created_at > 72.hours.ago

    !@read_post_ids.include?(@post.id)
  end

  sig { returns(T::Boolean) }
  def ooc?
    @post.is_ooc?
  end

  # Manuscript-style card. In-character posts are white; OOC posts take the
  # quiet blue tint (same family as former/retired). Unread posts glow.
  sig { returns(String) }
  def card_classes
    base = "attn-item rounded-post p-4 mb-3.5 last:mb-0"
    tint = ooc? ? "bg-tint-blue-bg border border-tint-blue-border" : "bg-card border border-card-border"
    hot = unread? ? "is-hot" : ""
    [ base, tint, hot ].reject(&:empty?).join(" ")
  end

  # Avatar tone: the GM's monogram is dark, players' are gold.
  sig { returns(Symbol) }
  def avatar_tone
    @game.game_master?(@post.user) ? :dark : :gold
  end
end
