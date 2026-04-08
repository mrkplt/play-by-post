require "rails_helper"

RSpec.describe Shared::NavShellComponent, type: :component do
  subject(:component) { described_class.new(current_user: current_user) }

  let(:current_user) { build_stubbed(:user, email: "jane@example.com") }

  before do
    allow(current_user).to receive(:display_name).and_return("Jane Doe")
    allow(current_user).to receive(:games).and_return(double(any?: false))
  end

  def rendered_component
    render_inline(component)
    page
  end

  it "passes current_user to the sidebar" do
    expect(rendered_component).to have_text("Jane Doe")
  end

  it "renders the hamburger button" do
    expect(rendered_component).to have_css("button[aria-label='Open navigation']")
  end

  it "renders the backdrop" do
    expect(rendered_component).to have_css(".sidebar-backdrop", visible: :all)
  end

  it "renders the sidebar aside" do
    expect(rendered_component).to have_css("aside.sidebar")
  end

  it "wires the hamburger to the sidebar controller open action" do
    expect(rendered_component).to have_css("button[data-action='click->sidebar#open']")
  end

  it "wires the backdrop to the sidebar controller close action" do
    expect(rendered_component).to have_css("[data-action='click->sidebar#close']")
  end
end
