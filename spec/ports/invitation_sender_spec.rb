# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ports::InvitationSender do
  it "is a Sorbet interface module" do
    expect(described_class).to be_a(Module)
  end

  it "declares send_invite as an abstract method" do
    expect(described_class.instance_method(:send_invite)).not_to be_nil
  end

  it "raises NotImplementedError when abstract methods are called without an implementation" do
    impl = Class.new { include Ports::InvitationSender }.new
    expect { impl.send_invite(invitation: nil) }.to raise_error(NotImplementedError)
  end
end
