# @label Post Item
class Shared::PostItemComponentPreview < ViewComponent::Preview
  # A stand-in for the request's Pundit policy / url_helpers, so the preview
  # can build a PostPresenter without a real controller in the loop.
  PreviewPostPolicy = Struct.new(:update?)
  PreviewUrls = Struct.new(:url) do
    def mark_read_game_scene_post_path(*)
      url
    end

    def edit_game_scene_post_path(*)
      url
    end
  end

  def default
    post = Post.first || Post.new(content: "Sample post content", is_ooc: false, created_at: Time.current)
    game = Game.first || Game.new(name: "Sample Game")
    presenter = build_presenter(post, game)
    render(Shared::PostItemComponent.new(post: presenter))
  end

  def ooc_post
    post = Post.new(content: "This is an out-of-character note.", is_ooc: true, created_at: Time.current)
    game = Game.new(name: "Sample Game")
    presenter = build_presenter(post, game)
    render(Shared::PostItemComponent.new(post: presenter))
  end

  def with_markdown
    post = Post.new(
      content: "**Bold**, *italic*, and a [link](https://example.com).\n\n- Item one\n- Item two",
      is_ooc: false,
      created_at: Time.current
    )
    game = Game.new(name: "Sample Game")
    presenter = build_presenter(post, game)
    render(Shared::PostItemComponent.new(post: presenter))
  end

  private

  def build_presenter(post, game)
    PostPresenter.new(post, game: game, urls: PreviewUrls.new("#"), policy: PreviewPostPolicy.new(false))
  end
end
