# @label Notebook Lane Select
class Shared::NotebookLaneSelectComponentPreview < ViewComponent::Preview
  def new_lane
    render(Shared::NotebookLaneSelectComponent.new(game: sample_game, notebook_entry: sample_entry("new")))
  end

  def expand_lane
    render(Shared::NotebookLaneSelectComponent.new(game: sample_game, notebook_entry: sample_entry("expand")))
  end

  def discarded
    render(Shared::NotebookLaneSelectComponent.new(game: sample_game, notebook_entry: sample_entry("discard")))
  end

  private

  def sample_game
    Game.new(id: 1, name: "Sample Game")
  end

  def sample_entry(status)
    NotebookEntry.new(
      id: 1,
      title: "A wandering merchant",
      slug: "samplenotebook01",
      status: status
    )
  end
end
