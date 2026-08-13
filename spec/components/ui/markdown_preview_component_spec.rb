require "rails_helper"

RSpec.describe Ui::MarkdownPreviewComponent, type: :component do
  it "renders an empty preview target the Stimulus controller can fill" do
    render_inline(described_class.new)
    expect(page).to have_css("[data-markdown-preview-target='preview']")
    expect(page.find("[data-markdown-preview-target='preview']").text).to be_empty
  end

  it "is uncapped and does not scroll without a height" do
    render_inline(described_class.new)
    preview = page.find("[data-markdown-preview-target='preview']")
    expect(preview["class"]).to eq(described_class::BASE)
    expect(preview["style"]).to be_blank
  end

  it "caps and scrolls at the configured step" do
    render_inline(described_class.new(height: :md))
    preview = page.find("[data-markdown-preview-target='preview']")
    expect(preview["class"]).to eq("#{described_class::BASE} overflow-y-auto")
    expect(preview["style"]).to eq("max-height: 30vh")
  end

  it "renders every step of the height scale" do
    Ui::MarkdownEditorComponent::Config::HEIGHTS.each do |step, value|
      render_inline(described_class.new(height: step))
      expect(page.find("[data-markdown-preview-target='preview']")["style"]).to eq("max-height: #{value}")
    end
  end

  it "rejects a height outside the scale" do
    expect { render_inline(described_class.new(height: :enormous)) }.to raise_error(KeyError)
  end

  it "appends caller classes after the base classes" do
    render_inline(described_class.new(height: :md, content_class: "post-content border"))
    expect(page.find("[data-markdown-preview-target='preview']")["class"])
      .to eq("#{described_class::BASE} overflow-y-auto post-content border")
  end

  it "appends caller classes when uncapped" do
    render_inline(described_class.new(content_class: "post-content"))
    expect(page.find("[data-markdown-preview-target='preview']")["class"])
      .to eq("#{described_class::BASE} post-content")
  end
end
