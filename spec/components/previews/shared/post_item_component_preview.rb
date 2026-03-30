# @label Post Item
class Shared::PostItemComponentPreview < ViewComponent::Preview
  def default
    post = Post.first || Post.new(content: "Sample post content", is_ooc: false, created_at: Time.current)
    game = Game.first || Game.new(name: "Sample Game")
    presenter = PostPresenter.new(post)
    render(Shared::PostItemComponent.new(post: presenter, game: game, current_user: User.first || User.new))
  end

  def ooc_post
    post = Post.new(content: "This is an out-of-character note.", is_ooc: true, created_at: Time.current)
    game = Game.new(name: "Sample Game")
    presenter = PostPresenter.new(post)
    render(Shared::PostItemComponent.new(post: presenter, game: game, current_user: User.new))
  end

  def with_markdown
    post = Post.new(
      content: "**Bold**, *italic*, and a [link](https://example.com).\n\n- Item one\n- Item two",
      is_ooc: false,
      created_at: Time.current
    )
    game = Game.new(name: "Sample Game")
    presenter = PostPresenter.new(post)
    render(Shared::PostItemComponent.new(post: presenter, game: game, current_user: User.new))
  end
end
