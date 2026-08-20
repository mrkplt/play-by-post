# typed: strict

class Shared::PostItemComponent < ApplicationComponent
  extend T::Sig

  CARD_BASE = T.let("attn-item rounded-post p-4 mb-3.5 last:mb-0", String)

  sig do
    params(
      post: PostPresenter,
      scene: T.nilable(ScenePresenter),
      read_post_ids: T.nilable(T::Set[Integer])
    ).void
  end
  def initialize(post:, scene: nil, read_post_ids: nil)
    @post = post
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
    [ CARD_BASE, card_tint, card_glow ].reject(&:empty?).join(" ")
  end

  # Avatar tone: the GM's monogram is dark, players' are gold.
  sig { returns(Symbol) }
  def avatar_tone
    @post.author_is_gm? ? :dark : :gold
  end

  # Post body typography: OOC posts read a touch smaller than in-character ones.
  sig { returns(Symbol) }
  def body_variant
    ooc? ? :post_body_ooc : :post_body
  end

  # The byline timestamp as a semantic <time> element, passed to the identity
  # block as its (HTML) secondary label. `data-local-time` lets the client
  # localize the displayed value.
  sig { returns(String) }
  def byline_time
    content_tag(:time, @post.formatted_created_at, data: { local_time: @post.created_at.iso8601 })
  end

  private

  sig { returns(String) }
  def card_tint
    ooc? ? "bg-tint-blue-bg border border-tint-blue-border" : "bg-card border border-card-border"
  end

  sig { returns(String) }
  def card_glow
    unread? ? "is-hot" : ""
  end
end
