require "rails_helper"

RSpec.describe Ui::MarkdownEditorComponent, type: :component do
  def build_form_builder
    ActionView::Helpers::FormBuilder.new(:feedback, nil, vc_test_view_context, {})
  end

  def render_editor(**overrides)
    render_inline(described_class.new(**{ form: build_form_builder, field: :body }.merge(overrides)))
  end

  def config(**overrides)
    described_class::Config.new(**overrides)
  end

  it "renders the toolbar, textarea and live preview" do
    render_editor
    expect(page).to have_css("[role='toolbar'][aria-label='Markdown formatting']")
    expect(page).to have_css("textarea[name='feedback[body]'][data-markdown-preview-target='input'][data-markdown-toolbar-target='input']")
    expect(page).to have_css("[data-markdown-preview-target='preview']")
  end

  it "owns the markdown controllers on its wrapper" do
    render_editor
    expect(page).to have_css("[data-controller~='markdown-preview'][data-controller~='markdown-toolbar']")
  end

  describe "regions" do
    it "places the toolbar above the textarea and the preview below it" do
      render_editor
      order = page.native.css("[role='toolbar'], textarea, [data-markdown-preview-target='preview']").map do |node|
        node.name == "textarea" ? :textarea : node["role"] == "toolbar" ? :toolbar : :preview
      end
      expect(order).to eq(%i[toolbar textarea preview])
    end

    it "omits a region the config does not carry" do
      render_editor(config: config(regions: [ described_class::ToolbarRegion.new ]))
      expect(page).to have_css("[role='toolbar']")
      expect(page).not_to have_css("[data-markdown-preview-target='preview']")
    end

    it "renders only the textarea when the config carries no regions" do
      render_editor(config: config(regions: []))
      expect(page).to have_css("textarea[name='feedback[body]']")
      expect(page).not_to have_css("[role='toolbar']")
      expect(page).not_to have_css("[data-markdown-preview-target='preview']")
    end

    it "renders a preview without the toolbar" do
      render_editor(config: config(regions: [ described_class::PreviewRegion.new(height: :md) ]))
      expect(page).not_to have_css("[role='toolbar']")
      expect(page).to have_css("[data-markdown-preview-target='preview'][style='max-height: 30vh']")
    end

    it "reports each region's placement" do
      expect(described_class::ToolbarRegion.new.placement).to eq(:above)
      expect(described_class::PreviewRegion.new.placement).to eq(:below)
    end
  end

  describe "textarea height" do
    it "caps the textarea at the configured step" do
      render_editor
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["style"]).to eq("max-height: 40vh")
      expect(textarea["class"]).to eq("markdown-editor w-full #{described_class::EDIT_BASE} overflow-y-auto")
    end

    it "leaves the textarea uncapped when no height is given" do
      render_editor(config: config(edit_height: nil))
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["style"]).to be_nil
      expect(textarea["class"]).to eq("markdown-editor w-full #{described_class::EDIT_BASE}")
    end

    it "renders every step of the height scale" do
      described_class::Config::HEIGHTS.each do |step, value|
        render_editor(config: config(edit_height: step))
        expect(page.find("textarea[name='feedback[body]']")["style"]).to eq("max-height: #{value}")
      end
    end

    it "rejects a height outside the scale rather than emitting an empty max-height" do
      expect { render_editor(config: config(edit_height: :enormous)) }.to raise_error(KeyError)
    end
  end

  describe "textarea attributes" do
    it "renders the value, placeholder and required flag" do
      render_editor(value: "draft text", placeholder: "Say something…", required: true)
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea).to have_content("draft text")
      expect(textarea["placeholder"]).to eq("Say something…")
      expect(textarea["required"]).to eq("required")
    end

    it "is not required and carries no value by default" do
      render_editor
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["required"]).to be_nil
      expect(textarea.text.strip).to be_empty
      component = described_class.new(form: build_form_builder, field: :body)
      expect(component.textarea_options.key?(:value)).to be(false)
    end

    it "merges caller data attributes onto the textarea" do
      render_editor(data: { post_draft_target: "content", action: "input->markdown-preview#update input->post-draft#scheduleSave" })
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["data-post-draft-target"]).to eq("content")
      expect(textarea["data-action"]).to eq("input->markdown-preview#update input->post-draft#scheduleSave")
    end

    it "applies the requested rows" do
      render_editor(rows: 12)
      expect(page).to have_css("textarea[rows='12']")
    end

    it "defaults to five rows" do
      render_editor
      expect(page).to have_css("textarea[rows='5']")
    end
  end

  describe "styling" do
    it "styles the textarea itself, so no caller respells the tokens" do
      render_editor
      expect(page.find("textarea[name='feedback[body]']")["class"])
        .to eq("markdown-editor w-full #{described_class::EDIT_BASE} overflow-y-auto")
    end

    it "assembles the edit classes into one space-joined string" do
      component = described_class.new(form: build_form_builder, field: :body)
      expect(component.edit_classes)
        .to be_a(String)
        .and eq("markdown-editor w-full #{described_class::EDIT_BASE} overflow-y-auto")
    end

    it "styles the textarea identically whatever the caller configures" do
      render_editor
      styled = page.find("textarea[name='feedback[body]']")["class"]
      render_editor(config: described_class::Config.with_preview(content_class: "post-content"), rows: 20)
      expect(page.find("textarea[name='feedback[body]']")["class"].include?(described_class::EDIT_BASE)).to be(true)
      expect(styled).to include(described_class::EDIT_BASE)
    end

    it "accepts a wrapper class, which positions the editor rather than styling it" do
      render_editor(wrapper_class: "mb-3")
      expect(page).to have_css("div.mb-3[data-controller~='markdown-preview']")
    end

    it "passes a content hook through to the preview without restyling it" do
      render_editor(config: described_class::Config.with_preview(content_class: "post-content"))
      expect(page.find("[data-markdown-preview-target='preview']")["class"])
        .to eq("#{Ui::MarkdownPreviewComponent::BASE} overflow-y-auto post-content")
    end
  end

  describe described_class::Config do
    it "defaults to a capped textarea with a toolbar and preview" do
      subject_config = described_class.new
      expect(subject_config.edit_max_height).to eq("max-height: 40vh")
      expect(subject_config.components_placed(:above).map(&:class)).to eq([ Shared::MarkdownToolbarComponent ])
      expect(subject_config.components_placed(:below).map(&:class)).to eq([ Ui::MarkdownPreviewComponent ])
    end

    it "caps the default preview, so an editor does not grow without bound" do
      preview = described_class.new.components_placed(:below).first
      expect(preview.max_height).to eq("max-height: #{described_class::HEIGHTS.fetch(:md)}")
    end

    it "needs no content hook — most callers have no domain styling to add" do
      preview = described_class.with_preview.components_placed(:below).first
      expect(preview.classes).to eq("#{Ui::MarkdownPreviewComponent::BASE} overflow-y-auto")
    end

    it "builds the common toolbar-plus-preview surface with .with_preview" do
      subject_config = described_class.with_preview(content_class: "post-content")
      expect(subject_config.edit_scroll?).to be(false)
      expect(subject_config.components_placed(:above).map(&:class)).to eq([ Shared::MarkdownToolbarComponent ])
      expect(subject_config.components_placed(:below).map(&:class)).to eq([ Ui::MarkdownPreviewComponent ])
    end

    it "reports whether the textarea is capped" do
      expect(described_class.new(edit_height: :md).edit_scroll?).to be(true)
      expect(described_class.new(edit_height: nil).edit_scroll?).to be(false)
    end

    it "resolves the textarea max-height from the scale" do
      expect(described_class.new(edit_height: :xl).edit_max_height).to eq("max-height: 60vh")
      expect(described_class.new(edit_height: nil).edit_max_height).to be_nil
    end

    it "selects only the components placed at the requested position" do
      subject_config = described_class.new(regions: [ Ui::MarkdownEditorComponent::ToolbarRegion.new ])
      expect(subject_config.components_placed(:above).size).to eq(1)
      expect(subject_config.components_placed(:below)).to be_empty
    end
  end
end
