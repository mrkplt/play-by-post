require "rails_helper"

RSpec.describe NotificationMailerDeliverySerializer do
  let(:scene) { create(:scene) }
  let(:recipient) { create(:user) }
  let(:delivery) { NotificationMailer::Delivery.new(scene: scene, recipient: recipient) }
  let(:serializer) { described_class.instance }

  it "serializes the delivery it is registered for" do
    expect(serializer.klass).to eq(NotificationMailer::Delivery)
  end

  it "round-trips a delivery through serialize and deserialize" do
    restored = serializer.deserialize(serializer.serialize(delivery))

    expect(restored).to be_a(NotificationMailer::Delivery)
    expect(restored.scene).to eq(scene)
    expect(restored.recipient).to eq(recipient)
  end

  it "carries the scene and recipient through the same job serialization ActiveJob uses" do
    hash = serializer.serialize(delivery)

    # Values are serialized through ActiveJob::Arguments, so records travel as
    # GlobalIDs rather than raw attributes — proving deliver_later can round-trip them.
    expect(serializer.deserialize(hash).scene).to eq(scene)
    expect(serializer.deserialize(hash).recipient).to eq(recipient)
  end
end
