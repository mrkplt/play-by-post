# @label Post Composer
class Shared::PostComposerComponentPreview < ViewComponent::Preview
  def default
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 1, title: "The Tavern")
    post  = Post.new
    render(Shared::PostComposerComponent.new(post: post, game: game, scene: scene))
  end

  def with_validation_error
    game  = Game.new(id: 1, name: "Sample Game")
    scene = Scene.new(id: 1, title: "The Tavern")
    post  = Post.new
    post.errors.add(:content, "can't be blank")
    render(Shared::PostComposerComponent.new(post: post, game: game, scene: scene))
  end

  def images_disabled
    game  = Game.new(id: 1, name: "Sample Game", images_disabled: true)
    scene = Scene.new(id: 1, title: "The Tavern")
    post  = Post.new
    render(Shared::PostComposerComponent.new(post: post, game: game, scene: scene))
  end
end
