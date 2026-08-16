require "rails_helper"

RSpec.describe Shared::TemplateFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy, manage?: true), urls: urls) }

  def presenter_for(template)
    ContentTemplatePresenter.new(template, game: game, urls: urls)
  end

  def build_component(template)
    described_class.new(game: game_presenter, template: presenter_for(template))
  end

  context "for a new template", :db do
    let(:game) { create(:game) }
    let(:template) { game.content_templates.new }

    subject(:component) { build_component(template) }

    it "is in new-record mode with the create label" do
      expect(component.new_record?).to be(true)
      expect(component.submit_label).to eq("Create Template")
    end

    it "offers a content-type select of the available types" do
      render_inline(component)
      expect(page).to have_css("select[name='content_template[content_type]']")
    end

    it "gives the new form its stable id" do
      expect(component.form_id).to eq("new_content_template_form")
      render_inline(component)
      expect(page).to have_css("form#new_content_template_form")
    end
  end

  context "for a persisted template" do
    let(:template) { build_stubbed(:content_template, game: game, content_type: "page") }

    subject(:component) { build_component(template) }

    it "is in edit mode with the save label" do
      expect(component.new_record?).to be(false)
      expect(component.submit_label).to eq("Save")
    end

    it "shows the fixed content type rather than a select" do
      render_inline(component)
      expect(page).to have_no_css("select[name='content_template[content_type]']")
      expect(page).to have_text("Page")
    end

    it "gives the edit form its stable id" do
      expect(component.form_id).to eq("edit_content_template_form")
      render_inline(component)
      expect(page).to have_css("form#edit_content_template_form")
    end

    it "surfaces validation errors from the record" do
      invalid = build_stubbed(:content_template, game: game, content_type: "page")
      allow(invalid).to receive_message_chain(:errors, :any?).and_return(true)
      allow(invalid).to receive_message_chain(:errors, :full_messages).and_return([ "Body can't be blank" ])
      form = described_class.new(game: game_presenter, template: presenter_for(invalid))

      expect(form.error_messages).to eq([ "Body can't be blank" ])
    end
  end
end
