require "rails_helper"

RSpec.describe TokenBearerAuthentication do
  # A minimal host that mixes in the concern, to unit-test its contract directly.
  let(:host_class) do
    Class.new do
      include TokenBearerAuthentication
    end
  end

  subject(:host) { host_class.new }

  describe "#pundit_user" do
    it "is nil before a bearer is authenticated" do
      expect(host.pundit_user).to be_nil
    end

    it "returns the actor set by authenticate_bearer!" do
      actor = Object.new
      host.authenticate_bearer!(actor)
      expect(host.pundit_user).to be(actor)
    end

    it "reflects the most recent actor" do
      host.authenticate_bearer!(:first)
      host.authenticate_bearer!(:second)
      expect(host.pundit_user).to eq(:second)
    end
  end
end
