# @label Notebook Card
class Shared::NotebookCardComponentPreview < ViewComponent::Preview
  def new_lane
    game = Game.new(name: "Sample Game")
    entry = NotebookEntry.new(title: "A wandering merchant", body: "Shows up in the next market scene.", status: "new")
    render(Shared::NotebookCardComponent.new(game: game, notebook_entry: entry))
  end

  def expand_lane
    game = Game.new(name: "Sample Game")
    entry = NotebookEntry.new(title: "The sunken temple", body: "Needs a map and a guardian encounter.", status: "expand")
    render(Shared::NotebookCardComponent.new(game: game, notebook_entry: entry))
  end

  def promoted
    game = Game.new(name: "Sample Game")
    page = Page.new(title: "The Sunken Temple")
    entry = NotebookEntry.new(title: "The sunken temple", body: "Now a full page.", status: "done", promoted_page: page)
    render(Shared::NotebookCardComponent.new(game: game, notebook_entry: entry))
  end

  def edit_mode
    game = Game.new(name: "Sample Game")
    entry = NotebookEntry.new(title: "A wandering merchant", body: "Shows up in the next market scene.", status: "new")
    render(Shared::NotebookCardComponent.new(game: game, notebook_entry: entry, mode: :edit))
  end
end
