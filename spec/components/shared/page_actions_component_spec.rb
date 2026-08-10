require "rails_helper"

RSpec.describe Shared::PageActionsComponent, type: :component do
  it "renders the primary slot" do
    render_inline(described_class.new) do |c|
      c.with_primary { "Save" }
    end
    expect(page).to have_text("Save")
  end

  it "omits the cancel slot when not given" do
    render_inline(described_class.new) do |c|
      c.with_primary { "Save" }
    end
    expect(page).not_to have_text("Cancel")
  end

  it "renders both primary and cancel when both are given" do
    render_inline(described_class.new) do |c|
      c.with_primary { "Save" }
      c.with_cancel { "Cancel" }
    end
    expect(page).to have_text("Save")
    expect(page).to have_text("Cancel")
  end

  it "reports cancel? based on whether the cancel slot is set" do
    component = described_class.new
    render_inline(component) { |c| c.with_primary { "Save" } }
    expect(component.cancel?).to be false
  end
end
