# @label Notebook Board
class Shared::NotebookBoardComponentPreview < ViewComponent::Preview
  # A board double for the preview: NotebookBoardPresenter itself queries the
  # database, which previews (in-memory, unsaved records) do not have.
  PreviewBoard = Struct.new(:entries_by_status) do
    def entries_for(status)
      entries_by_status.fetch(status, [])
    end
  end

  def default
    game = Game.new(id: 1, name: "Sample Game")
    entries_by_status = {
      "new" => [ presenter_for(game, title: "A wandering merchant", body: "Shows up next market day.", status: "new") ],
      "expand" => [ presenter_for(game, title: "The sunken temple", body: "Needs a map.", status: "expand") ],
      "done" => [],
      "discard" => [ presenter_for(game, title: "Scrapped subplot", body: "Didn't fit.", status: "discard") ]
    }
    render(Shared::NotebookBoardComponent.new(game: game_presenter(game), board: PreviewBoard.new(entries_by_status)))
  end

  def empty
    game = Game.new(id: 1, name: "Sample Game")
    render(Shared::NotebookBoardComponent.new(game: game_presenter(game), board: PreviewBoard.new({})))
  end

  private

  def presenter_for(game, title:, body:, status:)
    NotebookEntryPresenter.new(NotebookEntry.new(game: game, title: title, body: body, status: status))
  end

  def game_presenter(game)
    GamePresenter.new(game, policy: nil)
  end
end
