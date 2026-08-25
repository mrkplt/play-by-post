require "rails_helper"

RSpec.describe Shared::SidebarComponent, type: :component do
  subject(:component) { described_class.new(current_user: current_user_presenter, games: games) }

  let(:games) { [] }

  # Render once per example: ViewComponent 4.15 raises ReusedInstanceError if
  # the same instance is rendered twice (GHSA-8qw7-6phv-7q6p).
  def rendered_component
    @rendered_component ||= begin
      render_inline(component)
      page
    end
  end

  context "when signed out" do
    let(:current_user_presenter) { nil }

    it "renders the brand link" do
      expect(rendered_component).to have_css(".sidebar-brand")
      expect(rendered_component).to have_link(Branding.display_name)
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
    let(:user) { build_stubbed(:user, email: "jane@example.com") }
    let(:current_user_presenter) { UserPresenter.new(user) }

    before do
      allow(user).to receive(:display_name).and_return("Jane Doe")
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

    context "with games" do
      let(:game) { build_stubbed(:game, name: "Sunken Archive") }
      let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy, manage?: can_manage)) }
      let(:games) { [ game_presenter ] }

      context "when the viewer may administer the game" do
        let(:can_manage) { true }

        it "renders the game name and the crown" do
          html = rendered_component
          expect(html).to have_text("Sunken Archive")
          expect(html).to have_css(".sidebar-link svg.text-accent")
        end
      end

      context "when the viewer may not administer the game" do
        let(:can_manage) { false }

        it "renders the game name without a crown" do
          html = rendered_component
          expect(html).to have_text("Sunken Archive")
          expect(html).not_to have_css(".sidebar-link svg.text-accent")
        end
      end
    end

    context "without games" do
      it "does not render any game links" do
        expect(rendered_component).not_to have_css(".sidebar-link[href^='/games/']")
      end
    end
  end
end
