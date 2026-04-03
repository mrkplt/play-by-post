# typed: true

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
end
