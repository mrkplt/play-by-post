require "rails_helper"

RSpec.describe Ai::Funding do
  class FundingFakeKeySource
    include AiKeyResolver::KeySource
    def for_user(user) = "key-#{user.id}"
  end

  let(:game) { create(:game) }
  let(:resolver) { AiKeyResolver.new(key_source: FundingFakeKeySource.new) }
  subject(:funding) { described_class.new(resolver: resolver, feature: "scene_summary", game: game) }

  def authorize(n)
    allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
    n.times { create(:game_key_authorization, game: game, user: create(:user), feature: "scene_summary") }
  end

  def faraday_error(status)
    error = Faraday::Error.new("boom")
    allow(error).to receive(:response_status).and_return(status)
    error
  end

  it "yields a key and returns the block's value on success" do
    authorize(1)
    result = funding.call { |key| "used:#{key}" }
    expect(result).to start_with("used:key-")
  end

  it "raises Exhausted when the pool is empty" do
    expect { funding.call { |_key| "never" } }.to raise_error(described_class::Exhausted)
  end

  [ 401, 402, 403, 429 ].each do |status|
    it "fails over to the next key on a #{status} failure and decrements the pool" do
      authorize(2)
      calls = 0
      result = funding.call do |key|
        calls += 1
        raise faraday_error(status) if calls == 1
        "ok:#{key}"
      end

      expect(calls).to eq(2)
      expect(result).to start_with("ok:")
    end
  end

  it "tries each key at most once, to exhaustion, when all keys fail" do
    authorize(3)
    calls = 0
    expect {
      funding.call do |_key|
        calls += 1
        raise faraday_error(402)
      end
    }.to raise_error(described_class::Exhausted)
    expect(calls).to eq(3)
  end

  it "aborts on a non-key error without trying the rest of the pool" do
    authorize(2)
    calls = 0
    expect {
      funding.call do |_key|
        calls += 1
        raise faraday_error(400)
      end
    }.to raise_error(Faraday::Error)
    expect(calls).to eq(1)
  end
end
