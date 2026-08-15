require "rails_helper"

RSpec.describe PostDraft, :db do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }
  let(:author) { create(:user, :with_profile) }
  let(:other) { create(:user, :with_profile) }

  before do
    create(:game_member, game: game, user: author)
    create(:scene_participant, scene: scene, user: author)
  end

  def draft_for(user = author) = described_class.new(scene, user)

  describe "#find" do
    it "returns nothing when the user has no draft" do
      expect(draft_for.find).to be_nil
    end

    it "returns the user's own draft" do
      record = create(:post, scene: scene, user: author, draft: true)

      expect(draft_for.find).to eq(record)
    end

    it "does not return another user's draft" do
      create(:post, scene: scene, user: other, draft: true)

      expect(draft_for.find).to be_nil
    end

    it "does not return a published post" do
      create(:post, scene: scene, user: author, draft: false)

      expect(draft_for.find).to be_nil
    end
  end

  describe "#save" do
    it "creates the draft on first save" do
      result = draft_for.save(content: "Half a thought", is_ooc: nil)

      expect(result.saved).to be(true)
      expect(result.draft.content).to eq("Half a thought")
      expect(result.draft.draft?).to be(true)
    end

    it "defaults is_ooc to false when not given" do
      expect(draft_for.save(content: "Words", is_ooc: nil).draft.is_ooc?).to be(false)
    end

    it "keeps is_ooc when given" do
      expect(draft_for.save(content: "Aside", is_ooc: true).draft.is_ooc?).to be(true)
    end

    it "reads a checked checkbox's \"1\" as true" do
      expect(draft_for.save(content: "Aside", is_ooc: "1").draft.is_ooc?).to be(true)
    end

    it "reads an explicit \"0\" as false rather than as a present string" do
      expect(draft_for.save(content: "In character", is_ooc: "0").draft.is_ooc?).to be(false)
    end

    it "updates the existing draft rather than making a second" do
      draft_for.save(content: "First", is_ooc: nil)

      expect { draft_for.save(content: "Second", is_ooc: nil) }
        .not_to change { scene.posts.drafts.where(user: author).count }
      expect(T.must(draft_for.find).content).to eq("Second")
    end
  end

  describe "#discard" do
    it "removes the draft" do
      create(:post, scene: scene, user: author, draft: true)

      expect { draft_for.discard }.to change { scene.posts.drafts.count }.by(-1)
    end

    it "does nothing when there is no draft" do
      expect { draft_for.discard }.not_to raise_error
    end
  end

  describe "#publish_target" do
    it "builds a new post for the user when there is no draft" do
      post = draft_for.publish_target(content: "Fresh")

      expect(post).to be_new_record
      expect(post.user).to eq(author)
      expect(post.content).to eq("Fresh")
    end

    it "promotes the existing draft out of draft state" do
      existing = create(:post, scene: scene, user: author, draft: true, content: "Started")

      post = draft_for.publish_target(content: "Finished")

      expect(post.id).to eq(existing.id)
      expect(post.draft).to be(false)
      expect(post.content).to eq("Finished")
    end

    it "clears the edited stamp when promoting, so a publish is not an edit" do
      create(:post, scene: scene, user: author, draft: true, last_edited_at: 1.hour.ago)

      expect(draft_for.publish_target(content: "Done").last_edited_at).to be_nil
    end
  end
end
