require "rails_helper"

RSpec.describe UserPresenter do
  let(:user) { build_stubbed(:user, email: "jane@example.com") }

  subject(:presenter) { described_class.new(user) }

  describe "#display_name_or_email" do
    context "when the user has a display name" do
      before { allow(user).to receive(:display_name).and_return("Lady Ashford") }

      it { expect(presenter.display_name_or_email).to eq("Lady Ashford") }
    end

    context "when the user has no display name" do
      before { allow(user).to receive(:display_name).and_return(nil) }

      it "returns the email prefix" do
        expect(presenter.display_name_or_email).to eq("jane")
      end
    end
  end

  describe "delegation" do
    it "delegates email to the model" do
      expect(presenter.email).to eq("jane@example.com")
    end
  end
end
