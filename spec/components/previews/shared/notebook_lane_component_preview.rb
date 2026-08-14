# @label Notebook Lane
class Shared::NotebookLaneComponentPreview < ViewComponent::Preview
  def populated
    render(lane(entries: [
      sample_entry(1, "A wandering merchant"),
      sample_entry(2, "The sunken temple"),
      sample_entry(3, "A very long entry title that runs past the row and truncates")
    ]))
  end

  def empty
    render(lane)
  end

  def collapsible_closed
    render(lane(status: "discard", disclosure: :collapsed))
  end

  def collapsible_open
    render(lane(status: "discard", disclosure: :expanded))
  end

  private

  def lane(status: "new", entries: [], **options)
    Shared::NotebookLaneComponent.new(
      game: GamePresenter.new(Game.new(id: 1, name: "Sample Game"), policy: nil),
      status: status,
      entries: entries,      **options
    )
  end

  def sample_entry(id, title)
    NotebookEntryPresenter.new(NotebookEntry.new(id: id, title: title, slug: "samplenotebook0#{id}", status: "new"))
  end
end
