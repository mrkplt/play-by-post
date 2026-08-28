require "rails_helper"

RSpec.describe ExportDeliveryPresenter do
  # A real UserPresenter (initialize's sig enforces the type at runtime);
  # display_name_or_full_email is stubbed on it.
  let(:user_presenter) do
    UserPresenter.new(build(:user)).tap { |p| allow(p).to receive(:display_name_or_full_email).and_return("Ada <ada@example.com>") }
  end

  subject(:presenter) do
    described_class.new(user_presenter, game: game, download_url: "https://x/y.zip", expires_days: 7)
  end

  let(:game) { GamePresenter.new(build(:game)) }

  it "greets the recipient by their display-name-or-email" do
    expect(presenter.recipient_name).to eq("Ada <ada@example.com>")
  end

  it "exposes the download url and expiry" do
    expect(presenter.download_url).to eq("https://x/y.zip")
    expect(presenter.expires_days).to eq(7)
  end

  it "returns the exported game when one is given" do
    expect(presenter.game).to eq(game)
  end

  it "returns nil game for an all-games export" do
    all_games = described_class.new(user_presenter, download_url: "u", expires_days: 1)
    expect(all_games.game).to be_nil
  end
end
