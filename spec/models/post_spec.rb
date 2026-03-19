require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it "requires content" do
      expect(build(:post, content: nil)).not_to be_valid
    end

    it "is valid with content" do
      expect(build(:post)).to be_valid
    end
  end

  describe "#editable_by?" do
    let(:author) { create(:user) }
    let(:other_user) { create(:user) }
    let(:post) { create(:post, user: author, created_at: 5.minutes.ago) }

    it "returns true for the author within the edit window" do
      expect(post.editable_by?(author)).to be true
    end

    it "returns false for a different user" do
      expect(post.editable_by?(other_user)).to be false
    end

    it "returns false after the edit window has passed" do
      old_post = create(:post, user: author, created_at: 11.minutes.ago)
      expect(old_post.editable_by?(author)).to be false
    end
  end

  describe "#within_edit_window?" do
    it "returns true for a recent post" do
      expect(create(:post, created_at: 1.minute.ago).within_edit_window?).to be true
    end

    it "returns false for an old post" do
      expect(create(:post, created_at: 11.minutes.ago).within_edit_window?).to be false
    end
  end
end
