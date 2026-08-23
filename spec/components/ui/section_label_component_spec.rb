require "rails_helper"

RSpec.describe Ui::SectionLabelComponent, type: :component do
  def rendered(**opts, &block)
    render_inline(described_class.new(**opts), &block)
    page
  end

  it "renders the content block" do
    expect(rendered { "Active Scenes" }).to have_css("div", text: "Active Scenes")
  end

  it "applies the uppercase muted base classes" do
    expect(rendered { "Characters" }).to have_css("div.uppercase.text-muted.font-bold")
  end

  it "returns the md base classes by default" do
    expect(described_class.new.classes).to eq("text-[11px] tracking-[0.05em] font-bold text-muted uppercase")
  end

  it "uses the smaller type scale for size :sm" do
    expect(described_class.new(size: :sm).classes).to include("text-[10px]").and include("tracking-[0.06em]")
  end

  it "rejects an unknown size" do
    expect { described_class.new(size: :xl) }.to raise_error(ArgumentError, /Unknown size/)
  end

  it "appends an extra html_class" do
    expect(described_class.new(html_class: "mt-4").classes).to end_with(" mt-4")
  end

  it "renders the extra html_class in the DOM" do
    expect(rendered(html_class: "mt-4") { "X" }).to have_css("div.mt-4")
  end

  describe "with an action slot" do
    def rendered_with_action
      render_inline(described_class.new) do |label|
        label.with_action { "View docs" }
        "API tokens"
      end
      page
    end

    it "renders both the label content and the action inline on one row" do
      view = rendered_with_action
      expect(view).to have_text("API tokens")
      expect(view).to have_text("View docs")
      expect(view).to have_css("div.flex.justify-between")
    end

    it "renders no action wrapper when no action is given" do
      expect(rendered { "API tokens" }).not_to have_css("div.justify-between")
    end
  end
end
