# typed: strict
# frozen_string_literal: true

# Sends the two scene-lifecycle notifications, skipping anyone who has muted
# the scene. New-scene mail also skips the actor, who does not need telling
# about their own scene; resolution mail goes to everyone, actor included.
class SceneNotifier
  extend T::Sig

  sig { params(scene: Scene).void }
  def initialize(scene)
    @scene = scene
  end

  sig { params(actor: User).void }
  def created(actor)
    deliver_to(@scene.users.where.not(id: actor.id)) do |recipient|
      NotificationMailer.new_scene(NotificationMailer::Delivery.new(scene: @scene, recipient: recipient))
    end
  end

  sig { void }
  def resolved
    deliver_to(@scene.users) do |recipient|
      NotificationMailer.scene_resolved(NotificationMailer::Delivery.new(scene: @scene, recipient: recipient))
    end
  end

  private

  sig { params(recipients: T.untyped, block: T.proc.params(user: User).returns(T.untyped)).void }
  def deliver_to(recipients, &block)
    recipients.each do |recipient|
      next if NotificationPreference.muted?(@scene, recipient)

      block.call(recipient).deliver_later
    end
  end
end
