# typed: true

class Shared::PostItemComponent < ApplicationComponent
  extend T::Sig

  sig { params(post: PostPresenter, game: Game, current_user: User).void }
  def initialize(post:, game:, current_user:)
    @post = post
    @game = game
    @current_user = current_user
  end
end
