# typed: false

require "rails_helper"

RSpec.describe Shared::SceneResolutionComponent, type: :component do
  it "renders the resolution as markdown inside a labelled card" do
    render_inline(described_class.new(resolution: "The dragon **fell**"))

    expect(page).to have_text("Resolution:")
    expect(page).to have_css(".markdown-base strong", text: "fell")
  end
end
