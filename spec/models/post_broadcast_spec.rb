require "rails_helper"

# Pushes a created/edited post to the scene's single [scene, :posts] stream.
# Asserts the stream targets (append the list / remove the empty state on create,
# replace the post on update) and that the viewer-neutral render carries no
# author-only Edit affordance but keeps the OOC marker each client filters on.
RSpec.describe PostBroadcast, type: :model do
  let(:game) { create(:game) }
  let(:author) { create(:user, :with_profile) }
  let(:scene) { create(:scene, game: game) }

  before { create(:game_member, game: game, user: author) }

  def posts_stream
    [ scene, :posts ]
  end

  describe "#created" do
    it "appends the post to the list and removes the empty state" do
      post = create(:post, scene: scene, user: author)

      elements = capture_turbo_stream_broadcasts(posts_stream) { described_class.new(post).created }
      by_action = elements.group_by { |el| el["action"] }

      expect(by_action["remove"].map { |el| el["target"] }).to eq([ PostBroadcast::EMPTY_STATE_TARGET ])
      expect(by_action["append"].map { |el| el["target"] }).to eq([ PostBroadcast::POSTS_TARGET ])
    end

    it "renders the post content without the author's Edit link" do
      post = create(:post, scene: scene, user: author, content: "Live from the scene.")

      elements = capture_turbo_stream_broadcasts(posts_stream) { described_class.new(post).created }
      append = elements.find { |el| el["action"] == "append" }

      expect(append.to_html).to include("Live from the scene.")
      expect(append.to_html).not_to include(">Edit<")
    end

    it "carries the OOC marker so each viewer's filter can hide it" do
      post = create(:post, :ooc, scene: scene, user: author)

      elements = capture_turbo_stream_broadcasts(posts_stream) { described_class.new(post).created }
      append = elements.find { |el| el["action"] == "append" }

      expect(append.to_html).to include('data-ooc="true"')
    end
  end

  describe "#updated" do
    it "replaces the post in place by its dom id" do
      post = create(:post, :edited, scene: scene, user: author, content: "Edited body.")

      elements = capture_turbo_stream_broadcasts(posts_stream) { described_class.new(post).updated }
      replace = elements.find { |el| el["action"] == "replace" }

      expect(replace["target"]).to eq(ActionView::RecordIdentifier.dom_id(post))
      expect(replace.to_html).to include("Edited body.")
      expect(replace.to_html).not_to include(">Edit<")
    end
  end
end
