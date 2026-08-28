require "rails_helper"

RSpec.describe SceneNotificationPresenter do
  let(:scene) { build(:scene, description: raw_description) }
  let(:raw_description) { "The vault door groans open." }
  let(:scene_presenter) { ScenePresenter.new(scene, urls: double("urls")) }

  subject(:presenter) do
    described_class.new(scene_presenter, scene_url: "https://x/scene", mute_url: "https://x/mute")
  end

  it "exposes the scene title" do
    allow(scene_presenter).to receive(:title).and_return("The Reckoning")
    expect(presenter.title).to eq("The Reckoning")
  end

  it "returns the scene description when present" do
    expect(presenter.description).to eq("The vault door groans open.")
  end

  context "when the scene has no description" do
    let(:raw_description) { "" }

    it "returns nil (not a blank string) so the template's presence gate is clean" do
      expect(presenter.description).to be_nil
    end
  end

  it "exposes the scene and mute urls" do
    expect(presenter.scene_url).to eq("https://x/scene")
    expect(presenter.mute_url).to eq("https://x/mute")
  end

  it "delegates resolution to the wrapped scene presenter" do
    allow(scene_presenter).to receive(:resolution).and_return("And so it ended.")
    expect(presenter.resolution).to eq("And so it ended.")
  end

  it "defaults post_presenters to empty and extra_count to zero" do
    expect(presenter.post_presenters).to eq([])
    expect(presenter.extra_count).to eq(0)
  end

  it "carries digest posts and the extra count when given" do
    posts = [ instance_double(PostPresenter) ]
    digest = described_class.new(scene_presenter, scene_url: "u", mute_url: "m", post_presenters: posts, extra_count: 3)
    expect(digest.post_presenters).to eq(posts)
    expect(digest.extra_count).to eq(3)
  end
end
