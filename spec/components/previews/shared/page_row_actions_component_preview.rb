# @label Page Row Actions
class Shared::PageRowActionsComponentPreview < ViewComponent::Preview
  def default
    render(Shared::PageRowActionsComponent.new(
      game: Game.new(id: 1, name: "Sample Game"),
      page: Page.new(id: 1, title: "The Sunken Temple", slug: "samplepageslug01")))
  end
end
