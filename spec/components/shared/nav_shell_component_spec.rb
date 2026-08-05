require "rails_helper"

RSpec.describe Shared::NavShellComponent, type: :component do
  subject(:component) { described_class.new(current_user: current_user) }

  let(:current_user) { create(:user, email: "jane@example.com") }

  before do
    create(:user_profile, user: current_user, display_name: "Jane Doe")
  end

  def rendered_component
    render_inline(component)
    page
  end

  it "renders the nav drawer with the user's name" do
    expect(rendered_component).to have_text("Jane Doe")
  end

  it "renders the drawer backdrop" do
    expect(rendered_component).to have_css(".nav-drawer-backdrop", visible: :all)
  end

  it "renders the drawer aside" do
    expect(rendered_component).to have_css("aside.nav-drawer")
  end

  it "renders the feedback modal outside the drawer aside" do
    render_inline(component)
    expect(page).to have_css("[data-testid='feedback-modal']", visible: :all)
    expect(page).to have_no_css("aside.nav-drawer [data-testid='feedback-modal']", visible: :all)
  end

  it "wires the backdrop to the sidebar controller close action" do
    expect(rendered_component).to have_css(".nav-drawer-backdrop[data-action='click->sidebar#close']", visible: :all)
  end

  it "exposes current_user and active_game_id" do
    c = described_class.new(current_user: current_user, active_game_id: 7)
    expect(c.current_user).to eq(current_user)
    expect(c.active_game_id).to eq(7)
  end
end
