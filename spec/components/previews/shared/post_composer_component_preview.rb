# @label Post Composer
class Shared::PostComposerComponentPreview < ViewComponent::Preview
  # A stand-in for the request's Pundit policy / url_helpers, so the preview
  # can build presenters without a real controller in the loop.
  PreviewGamePolicy = Struct.new(:manage?)
  PreviewUrls = Struct.new(:save_draft_url) do
    def save_draft_game_scene_posts_path(*)
      save_draft_url
    end
  end

  def default
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 1, title: "The Tavern")
    post  = Post.new
    render(Shared::PostComposerComponent.new(
      post: PostPresenter.new(post),
      game: GamePresenter.new(game, policy: PreviewGamePolicy.new(true)),
      scene: ScenePresenter.new(scene, game: game, urls: PreviewUrls.new("#"))))
  end

  def with_validation_error
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 1, title: "The Tavern")
    post  = Post.new
    post.errors.add(:content, "can't be blank")
    render(Shared::PostComposerComponent.new(
      post: PostPresenter.new(post),
      game: GamePresenter.new(game, policy: PreviewGamePolicy.new(true)),
      scene: ScenePresenter.new(scene, game: game, urls: PreviewUrls.new("#"))))
  end

  def images_disabled
    game  = Game.new(id: 1, name: "Sample Game", images_disabled: true)
    scene = Scene.new(id: 1, title: "The Tavern")
    post  = Post.new
    render(Shared::PostComposerComponent.new(
      post: PostPresenter.new(post),
      game: GamePresenter.new(game, policy: PreviewGamePolicy.new(true)),
      scene: ScenePresenter.new(scene, game: game, urls: PreviewUrls.new("#"))))
  end
end
