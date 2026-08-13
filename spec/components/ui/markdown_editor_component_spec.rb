require "rails_helper"

RSpec.describe Ui::MarkdownEditorComponent, type: :component do
  def build_form_builder
    ActionView::Helpers::FormBuilder.new(:feedback, nil, vc_test_view_context, {})
  end

  def render_editor(**overrides)
    render_inline(described_class.new(**{ form: build_form_builder, field: :body }.merge(overrides)))
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

  describe "scroll behaviour" do
    it "caps the edit and preview regions by default (:both)" do
      render_editor
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["style"]).to eq("max-height: 40vh")
      expect(textarea["class"]).to eq("markdown-editor w-full overflow-y-auto")
      preview = page.find("[data-markdown-preview-target='preview']")
      expect(preview["class"]).to eq("markdown-base min-h-12 bg-canvas overflow-y-auto")
      expect(preview["style"]).to eq("max-height: 30vh")
    end

    it "caps only the edit region with :edit" do
      render_editor(config: described_class::Config.new(scroll: :edit, edit_height: :sm))
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["style"]).to eq("max-height: 20vh")
      expect(textarea["class"]).to eq("markdown-editor w-full overflow-y-auto")
      preview = page.find("[data-markdown-preview-target='preview']")
      expect(preview["style"]).to be_nil
      expect(preview["class"]).to eq("markdown-base min-h-12 bg-canvas")
    end

    it "caps only the preview with :preview" do
      render_editor(config: described_class::Config.new(scroll: :preview, preview_height: :xl))
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["style"]).to be_nil
      expect(textarea["class"]).to eq("markdown-editor w-full")
      expect(page).to have_css("[data-markdown-preview-target='preview'][style='max-height: 60vh']")
    end

    it "renders every step of the height scale" do
      described_class::Config::HEIGHTS.each do |step, value|
        render_editor(config: described_class::Config.new(scroll: :edit, edit_height: step))
        expect(page.find("textarea[name='feedback[body]']")["style"]).to eq("max-height: #{value}")
      end
    end

    it "rejects a height outside the scale rather than emitting an empty max-height" do
      expect {
        render_editor(config: described_class::Config.new(scroll: :edit, edit_height: :enormous))
      }.to raise_error(KeyError)
    end
  end

  describe "config" do
    it "applies the configured rows" do
      render_editor(config: described_class::Config.new(rows: 12))
      expect(page).to have_css("textarea[rows='12']")
    end

    it "omits the toolbar when disabled" do
      render_editor(config: described_class::Config.new(toolbar: false))
      expect(page).not_to have_css("[role='toolbar']")
    end

    it "omits the preview when disabled" do
      render_editor(config: described_class::Config.new(preview: false))
      expect(page).not_to have_css("[data-markdown-preview-target='preview']")
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
  end

  describe "class passthroughs" do
    it "appends extra classes to the textarea, preview and wrapper" do
      render_editor(
        edit_class: "px-3 bg-card",
        preview_class: "post-content border",
        wrapper_class: "mb-3"
      )
      textarea = page.find("textarea[name='feedback[body]']")
      expect(textarea["class"]).to eq("markdown-editor w-full overflow-y-auto px-3 bg-card")
      preview = page.find("[data-markdown-preview-target='preview']")
      expect(preview["class"]).to eq("markdown-base min-h-12 bg-canvas overflow-y-auto post-content border")
      expect(page).to have_css("div.mb-3[data-controller~='markdown-preview']")
    end
  end

  describe "class assembly" do
    it "joins the edit and preview classes into single strings" do
      component = described_class.new(form: build_form_builder, field: :body)
      expect(component.edit_classes).to eq("markdown-editor w-full overflow-y-auto")
      expect(component.preview_classes).to eq("markdown-base min-h-12 bg-canvas overflow-y-auto")
    end
  end

  describe described_class::Config do
    it "defaults to :both scroll with sensible heights" do
      config = described_class.new
      expect(config.scroll).to eq(:both)
      expect(config.edit_height).to eq(:lg)
      expect(config.preview_height).to eq(:md)
      expect(config.toolbar).to be(true)
      expect(config.preview).to be(true)
      expect(config.rows).to eq(5)
    end

    it "reports the scroll regions per mode" do
      expect(described_class.new(scroll: :both).edit_scroll?).to be(true)
      expect(described_class.new(scroll: :both).preview_scroll?).to be(true)
      expect(described_class.new(scroll: :edit).edit_scroll?).to be(true)
      expect(described_class.new(scroll: :edit).preview_scroll?).to be(false)
      expect(described_class.new(scroll: :preview).edit_scroll?).to be(false)
      expect(described_class.new(scroll: :preview).preview_scroll?).to be(true)
    end
  end
end
