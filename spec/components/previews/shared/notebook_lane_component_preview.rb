# @label Notebook Lane
class Shared::NotebookLaneComponentPreview < ViewComponent::Preview
  def populated
    render(Shared::NotebookLaneComponent.new(
      game: sample_game,
      status: "new",
      entries: [
        sample_entry(1, "A wandering merchant"),
        sample_entry(2, "The sunken temple"),
        sample_entry(3, "A very long entry title that runs past the row and truncates")
      ]))
  end

  def empty
    render(Shared::NotebookLaneComponent.new(game: sample_game, status: "new", entries: []))
  end

  def empty_discard
    render(Shared::NotebookLaneComponent.new(game: sample_game, status: "discard", entries: []))
  end

  private

  def sample_game
    Game.new(id: 1, name: "Sample Game")
  end

  def sample_entry(id, title)
    NotebookEntry.new(id: id, title: title, slug: "samplenotebook0#{id}", status: "new")
  end
end
