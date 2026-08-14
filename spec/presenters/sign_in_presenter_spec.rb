require "rails_helper"

RSpec.describe SignInPresenter do
  let(:user) { build_stubbed(:user) }

  describe "#email_sent?" do
    it "is true when constructed with email_sent: true" do
      presenter = described_class.new(user, email_sent: true)
      expect(presenter.email_sent?).to be(true)
    end

    it "is false by default" do
      presenter = described_class.new(user)
      expect(presenter.email_sent?).to be(false)
    end

    it "is false when constructed with email_sent: false" do
      presenter = described_class.new(user, email_sent: false)
      expect(presenter.email_sent?).to be(false)
    end
  end
end
