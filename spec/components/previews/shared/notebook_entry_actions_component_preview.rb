# @label Notebook Entry Actions
class Shared::NotebookEntryActionsComponentPreview < ViewComponent::Preview
  def default
    render(Shared::NotebookEntryActionsComponent.new(
      game: sample_game,
      notebook_entry: sample_entry))
  end

  def promoted
    entry = sample_entry
    entry.promoted_page = Page.new(id: 1, title: "The Sunken Temple", slug: "samplepageslug01")
    render(Shared::NotebookEntryActionsComponent.new(game: sample_game, notebook_entry: entry))
  end

  private

  def sample_game
    Game.new(id: 1, name: "Sample Game")
  end

  def sample_entry
    NotebookEntry.new(id: 1, title: "A wandering merchant", slug: "samplenotebook01", status: "new")
  end
end
