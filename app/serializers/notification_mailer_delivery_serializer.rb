# typed: true

# ActiveJob only knows how to serialize the argument types listed in its
# supported-types table (GlobalID records, primitives, Hash/Array of those).
# NotificationMailer::Delivery is a T::Struct, so mail(...).deliver_later
# raises ActiveJob::SerializationError unless this is registered — Active
# Record's own GlobalID serializer handles the scene/recipient values inside.
class NotificationMailerDeliverySerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize(delivery)
    super("scene" => serialize_one(delivery.scene), "recipient" => serialize_one(delivery.recipient))
  end

  def deserialize(hash)
    NotificationMailer::Delivery.new(
      scene: deserialize_one(hash["scene"]),
      recipient: deserialize_one(hash["recipient"])
    )
  end

  def klass
    NotificationMailer::Delivery
  end

  private

  def serialize_one(value)
    ActiveJob::Arguments.serialize([ value ]).first
  end

  def deserialize_one(value)
    ActiveJob::Arguments.deserialize([ value ]).first
  end
end
