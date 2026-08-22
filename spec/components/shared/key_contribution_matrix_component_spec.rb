require "rails_helper"

RSpec.describe Shared::KeyContributionMatrixComponent, type: :component do
  def row(name:, cells:)
    instance_double(KeyContributionRowPresenter, name: name, cells: cells)
  end

  def available_cell(path: "/toggle")
    KeyContributionRowPresenter::Available.new(label: "Scene summaries", feature: "scene_summary", path: path)
  end

  def offered_cell(path: "/destroy")
    KeyContributionRowPresenter::Offered.new(label: "Scene summaries", feature: "scene_summary", path: path)
  end

  it "renders a game name and a toggle per feature cell" do
    rendered = render_inline(described_class.new(rows: [ row(name: "Ashfall Reaches", cells: [ available_cell ]) ]))

    expect(rendered.text).to include("Ashfall Reaches")
    expect(rendered.text).to include("Scene summaries")
    expect(rendered.css("form[action='/toggle']")).to be_present
  end

  it "submits POST with the feature param when not yet contributing" do
    rendered = render_inline(described_class.new(rows: [ row(name: "G", cells: [ available_cell(path: "/create") ]) ]))

    expect(rendered.css("form[action='/create']")).to be_present
    expect(rendered.css("input[name='feature'][value='scene_summary']")).to be_present
    expect(rendered.css("form[action='/create'] input[name='_method'][value='delete']")).to be_empty
  end

  it "submits DELETE when already contributing" do
    rendered = render_inline(described_class.new(rows: [ row(name: "G", cells: [ offered_cell(path: "/destroy") ]) ]))

    expect(rendered.css("form[action='/destroy'] input[name='_method'][value='delete']")).to be_present
  end

  it "shows an empty-state message when the person is in no games" do
    rendered = render_inline(described_class.new(rows: []))
    expect(rendered.text).to include("Join a game")
  end
end
