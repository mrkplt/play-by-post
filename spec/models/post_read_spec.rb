require "rails_helper"

RSpec.describe PostRead, type: :model do
  describe "validations" do
    it "requires uniqueness of post per user" do
      existing = create(:post_read)
      duplicate = build(:post_read, post: existing.post, user: existing.user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:post_id]).to be_present
    end

    it "allows the same post to be read by different users" do
      post = create(:post)
      create(:post_read, post: post, user: create(:user))
      second = build(:post_read, post: post, user: create(:user))
      expect(second).to be_valid
    end
  end

  describe ".mark!" do
    let(:post) { create(:post) }
    let(:user) { create(:user) }

    it "creates a PostRead record" do
      expect { PostRead.mark!(post, user) }.to change(PostRead, :count).by(1)
    end

    it "is idempotent — does not raise on duplicate calls" do
      PostRead.mark!(post, user)
      expect { PostRead.mark!(post, user) }.not_to raise_error
    end

    it "does not create a second record on duplicate call" do
      PostRead.mark!(post, user)
      expect { PostRead.mark!(post, user) }.not_to change(PostRead, :count)
    end

    it "sets read_at on the record" do
      pr = PostRead.mark!(post, user)
      expect(pr.read_at).to be_present
    end
  end
end
