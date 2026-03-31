# @label Gallery
class Shared::GalleryComponentPreview < ViewComponent::Preview
  def empty
    game = Game.new(id: 1, name: "Sample Game")
    render(Shared::GalleryComponent.new(game_files: [], game: game))
  end

  def as_player
    game       = Game.first || Game.new(id: 1, name: "Sample Game")
    game_files = GameFile.where(game: game).limit(12)
    render(Shared::GalleryComponent.new(game_files: game_files.to_a, game: game, is_gm: false))
  end

  def as_gm
    game       = Game.first || Game.new(id: 1, name: "Sample Game")
    game_files = GameFile.where(game: game).limit(12)
    render(Shared::GalleryComponent.new(game_files: game_files.to_a, game: game, is_gm: true))
  end
end
