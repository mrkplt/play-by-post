require "rails_helper"

RSpec.describe Shared::GameFormComponent, type: :component do
  let(:game_model) { build_stubbed(:game, name: "Ashfall Reaches", description: "A grim saga") }
  let(:game) { GamePresenter.new(game_model, policy: instance_double(GamePolicy)) }

  def build_submission(**overrides)
    Shared::GameFormComponent::Submission.new(
      **{ label: "Save Changes", cancel_href: "/games/#{game_model.id}" }.merge(overrides)
    )
  end

  def build_component(submission: nil, **submission_overrides)
    described_class.new(game: game, submission: submission || build_submission(**submission_overrides))
  end

  describe "#note?" do
    it "is true when a note is supplied" do
      expect(build_component(note: "You will be the GM.").note?).to be(true)
    end

    it "is false when no note is supplied" do
      expect(build_component.note?).to be(false)
    end

    it "is false when the note is blank" do
      expect(build_component(note: "  ").note?).to be(false)
    end
  end

  describe "#submit_data" do
    it "carries a confirm prompt when one is supplied" do
      expect(build_component(confirm: "Sure?").submit_data).to eq(confirm: "Sure?")
    end

    it "is empty when no confirmation is requested" do
      expect(build_component.submit_data).to eq({})
    end
  end

  describe "errors" do
    it "renders no error block on a clean game" do
      component = build_component
      expect(component.error_messages).to be_empty
      render_inline(component)
      expect(page).to have_no_css(".text-danger")
    end

    it "surfaces validation messages when the game has errors" do
      game_model.errors.add(:name, "can't be blank")
      component = build_component
      expect(component.error_messages).to include("Name can't be blank")
      render_inline(component)
      expect(page).to have_css(".text-danger", text: "Name can't be blank")
    end
  end

  describe "rendering" do
    it "renders the name and description fields with the submit and cancel controls" do
      render_inline(build_component(label: "Create game", cancel_href: "/"))

      expect(page).to have_field("Name")
      expect(page).to have_field("Description (optional, markdown supported)")
      expect(page).to have_button("Create game")
      expect(page).to have_link("Cancel", href: "/")
    end

    it "wires the description field to the markdown toolbar and live preview" do
      render_inline(build_component)

      expect(page).to have_css("[data-controller~='markdown-preview'][data-controller~='markdown-toolbar']")
      expect(page).to have_css("textarea.markdown-editor[data-markdown-preview-target='input']")
      expect(page).to have_css("[role='toolbar'][aria-label='Markdown formatting']")
      expect(page).to have_css("[data-markdown-preview-target='preview']")
    end

    it "renders the note when supplied" do
      render_inline(build_component(note: "You will become the Game Master of this game."))
      expect(page).to have_text("You will become the Game Master of this game.")
    end

    it "omits the note when not supplied" do
      render_inline(build_component)
      expect(page).not_to have_text("Game Master")
    end

    it "shows validation messages in the error box" do
      game_model.errors.add(:name, "can't be blank")
      render_inline(build_component)
      expect(page).to have_text("Name can't be blank")
    end
  end
end
