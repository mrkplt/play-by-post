require "rails_helper"

RSpec.describe PostRead, type: :model do
  describe "validations" do
    it "declares uniqueness of post per user" do
      validator = PostRead.validators_on(:post_id)
        .find { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }

      expect(validator.options[:scope]).to eq(:user_id)
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

    it "finds or creates the read for that post and user" do
      allow(PostRead).to receive(:find_or_create_by!).and_return(build_stubbed(:post_read))

      PostRead.mark!(post, user)

      expect(PostRead).to have_received(:find_or_create_by!).with(post: post, user: user)
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
