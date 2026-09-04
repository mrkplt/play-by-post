require "rails_helper"

RSpec.describe Shared::PageRowActionsComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:page_record) { build_stubbed(:page, game: game, title: "Alpha", slug: "alpha00000000000") }

  def routes
    Rails.application.routes.url_helpers
  end

  # The row self-gates each action from the page's policy (Fizzy #18): Edit shows
  # iff #can_edit?, Delete iff #can_delete?.
  def build_component(edit: true, destroy: true)
    presenter = PagePresenter.new(
      page_record, game: game, urls: routes,
      game_policy: instance_double(GamePolicy),
      page_policy: instance_double(PagePolicy, update?: edit, destroy?: destroy)
    )
    described_class.new(page: presenter)
  end

  it "links Edit to the page's edit screen" do
    render_inline(build_component)
    expect(page).to have_link("Edit", href: routes.edit_game_page_path(game, page_record))
  end

  it "omits Edit when the viewer may not edit the page" do
    render_inline(build_component(edit: false))
    expect(page).to have_no_link("Edit")
  end

  it "targets the page's destroy route from Delete" do
    render_inline(build_component)
    form = page.find("form[action='#{routes.game_page_path(game, page_record)}']")
    expect(form).to have_field("_method", type: :hidden, with: "delete")
  end

  it "omits Delete when the viewer may not delete the page" do
    render_inline(build_component(destroy: false))
    expect(page).to have_no_button("Delete")
  end

  it "guards Delete with an are-you-sure confirmation" do
    render_inline(build_component)
    expect(page).to have_css("form[data-turbo-confirm='#{described_class::CONFIRM}']")
  end

  it "warns that deletion cannot be undone" do
    expect(build_component.confirm).to include("cannot be undone")
  end
end
