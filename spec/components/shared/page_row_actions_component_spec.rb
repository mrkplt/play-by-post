require "rails_helper"

RSpec.describe Shared::PageRowActionsComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:page_record) { build_stubbed(:page, game: game, title: "Alpha", slug: "alpha00000000000") }

  def routes
    Rails.application.routes.url_helpers
  end

  def build_component
    described_class.new(page: PagePresenter.new(page_record))
  end

  it "links Edit to the page's edit screen" do
    render_inline(build_component)
    expect(page).to have_link("Edit", href: routes.edit_game_page_path(game, page_record))
  end

  it "targets the page's destroy route from Delete" do
    render_inline(build_component)
    form = page.find("form[action='#{routes.game_page_path(game, page_record)}']")
    expect(form).to have_field("_method", type: :hidden, with: "delete")
  end

  it "guards Delete with an are-you-sure confirmation" do
    render_inline(build_component)
    expect(page).to have_css("form[data-turbo-confirm='#{described_class::CONFIRM}']")
  end

  it "warns that deletion cannot be undone" do
    expect(build_component.confirm).to include("cannot be undone")
  end
end
