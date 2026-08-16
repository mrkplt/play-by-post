require "rails_helper"

RSpec.describe Shared::TemplateRowActionsComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:template) do
    ContentTemplatePresenter.new(
      build_stubbed(:content_template, game: game, content_type: "page"), game: game, urls: urls
    )
  end

  it "renders Edit and Delete controls pointing at the template's routes" do
    render_inline(described_class.new(template: template))

    expect(page).to have_link("Edit", href: template.edit_path)
    expect(page).to have_button("Delete")
  end

  it "confirms before deleting" do
    render_inline(described_class.new(template: template))
    expect(page).to have_css("[data-turbo-confirm='Delete this template?']")
  end
end
