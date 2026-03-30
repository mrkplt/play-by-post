require "rails_helper"

RSpec.describe PostPresenter do
  let(:user) { build(:user, email: "author@example.com") }
  let(:post) { build(:post, user: user, content: "**bold** text", created_at: Time.zone.parse("2024-06-15 14:30:00")) }

  subject(:presenter) { described_class.new(post) }

  describe "#rendered_content" do
    it "renders markdown to HTML" do
      expect(presenter.rendered_content).to include("<strong>bold</strong>")
    end

    it "returns empty string for blank content" do
      allow(post).to receive(:content).and_return("")
      expect(described_class.new(post).rendered_content).to eq("")
    end
  end

  describe "#formatted_created_at" do
    it "formats the timestamp" do
      expect(presenter.formatted_created_at).to eq("Jun 15, 2024 2:30 PM")
    end
  end

  describe "#author_display_name" do
    context "without scene participants" do
      it "falls back to user email when no display name" do
        allow(user).to receive(:display_name).and_return(nil)
        expect(presenter.author_display_name).to eq("author@example.com")
      end

      it "uses user display name when present" do
        allow(user).to receive(:display_name).and_return("Jane Doe")
        expect(presenter.author_display_name).to eq("Jane Doe")
      end
    end

    context "with a matching scene participant" do
      let(:participant) do
        instance_double(SceneParticipant, user_id: user.id, display_name: "Lady Ashford")
      end

      subject(:presenter) { described_class.new(post, scene_participants: [ participant ]) }

      it "prefers the participant display name" do
        expect(presenter.author_display_name).to eq("Lady Ashford")
      end
    end

    context "with a non-matching scene participant" do
      let(:other_participant) do
        instance_double(SceneParticipant, user_id: 9999, display_name: "Someone Else")
      end

      subject(:presenter) { described_class.new(post, scene_participants: [ other_participant ]) }

      it "falls back to user display name" do
        allow(user).to receive(:display_name).and_return("Jane Doe")
        expect(presenter.author_display_name).to eq("Jane Doe")
      end
    end
  end

  describe "delegation" do
    it "delegates is_ooc? to the model" do
      allow(post).to receive(:is_ooc?).and_return(true)
      expect(presenter.is_ooc?).to be true
    end

    it "delegates editable_by? to the model" do
      allow(post).to receive(:editable_by?).with(user).and_return(true)
      expect(presenter.editable_by?(user)).to be true
    end
  end
end
