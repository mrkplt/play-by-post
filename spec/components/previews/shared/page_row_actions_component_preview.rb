# @label Page Row Actions
class Shared::PageRowActionsComponentPreview < ViewComponent::Preview
  def default
    page = Page.new(id: 1, title: "The Sunken Temple", slug: "samplepageslug01")
    page.game = Game.new(id: 1, name: "Sample Game")
    render(Shared::PageRowActionsComponent.new(page: PagePresenter.new(page)))
  end
end
