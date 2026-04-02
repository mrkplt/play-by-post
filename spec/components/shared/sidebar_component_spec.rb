require "rails_helper"

RSpec.describe Shared::SidebarComponent, type: :component do
  subject(:component) { described_class.new(current_user: current_user) }

  def rendered_component
    render_inline(component)
    page
  end

  context "when signed out" do
    let(:current_user) { nil }

    it "renders the brand link" do
      expect(rendered_component).to have_css(".sidebar-brand")
      expect(rendered_component).to have_link("Play by Post")
    end

    it "renders the My Games label" do
      expect(rendered_component).to have_text("My Games")
    end

    it "does not render the user section" do
      expect(rendered_component).not_to have_css(".sidebar-user")
    end

    it "does not render the sign out link" do
      expect(rendered_component).not_to have_link("Sign out")
    end
  end

  context "when signed in" do
    let(:current_user) { build_stubbed(:user, email: "jane@example.com") }

    before do
      allow(current_user).to receive(:display_name).and_return("Jane Doe")
      allow(current_user).to receive(:games).and_return(double(any?: false))
    end

    it "renders the user section" do
      expect(rendered_component).to have_css(".sidebar-user")
    end

    it "renders the display name" do
      expect(rendered_component).to have_text("Jane Doe")
    end

    it "renders the sign out link" do
      expect(rendered_component).to have_link("Sign out")
    end

    it "renders the profile settings link" do
      expect(rendered_component).to have_css("a[href='/profile']")
    end
  end

  describe "#game_master_in?" do
    let(:game) { build_stubbed(:game) }

    context "when signed out" do
      let(:current_user) { nil }

      it "returns false" do
        expect(component.game_master_in?(game)).to eq(false)
      end
    end

    context "when the user is a GM in the game" do
      let(:current_user) { build_stubbed(:user) }
      let(:member) { build_stubbed(:game_member, role: :game_master) }

      it "returns true" do
        allow(game).to receive(:member_for).with(current_user).and_return(member)
        expect(component.game_master_in?(game)).to eq(true)
      end
    end

    context "when the user is a player in the game" do
      let(:current_user) { build_stubbed(:user) }
      let(:member) { build_stubbed(:game_member, role: :player) }

      it "returns false" do
        allow(game).to receive(:member_for).with(current_user).and_return(member)
        expect(component.game_master_in?(game)).to eq(false)
      end
    end

    context "when the user is not a member of the game" do
      let(:current_user) { build_stubbed(:user) }

      it "returns false" do
        allow(game).to receive(:member_for).with(current_user).and_return(nil)
        expect(component.game_master_in?(game)).to eq(false)
      end
    end
  end
end
