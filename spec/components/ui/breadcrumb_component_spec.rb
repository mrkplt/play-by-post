require "rails_helper"

RSpec.describe Ui::BreadcrumbComponent, type: :component do
  def rendered(&block)
    render_inline(described_class.new, &block)
    page
  end

  it "renders as a nav element" do
    expect(rendered { "Games" }).to have_css("nav")
  end

  it "applies breadcrumb Tailwind classes" do
    expect(rendered { "Games" }).to have_css("nav.text-sm.mb-4.text-slate-500")
  end

  it "renders block content" do
    expect(rendered { "Games › My Game" }).to have_css("nav", text: "Games › My Game")
  end
end
