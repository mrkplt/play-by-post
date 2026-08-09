# @label Notebook Board
class Shared::NotebookBoardComponentPreview < ViewComponent::Preview
  def default
    game = Game.new(name: "Sample Game")
    entries_by_status = {
      "new" => [ NotebookEntry.new(title: "A wandering merchant", body: "Shows up next market day.", status: "new") ],
      "expand" => [ NotebookEntry.new(title: "The sunken temple", body: "Needs a map.", status: "expand") ],
      "done" => [],
      "discard" => [ NotebookEntry.new(title: "Scrapped subplot", body: "Didn't fit.", status: "discard") ]
    }
    render(Shared::NotebookBoardComponent.new(game: game, entries_by_status: entries_by_status))
  end

  def empty
    game = Game.new(name: "Sample Game")
    render(Shared::NotebookBoardComponent.new(game: game, entries_by_status: {}))
  end
end
