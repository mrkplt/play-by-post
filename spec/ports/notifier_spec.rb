# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ports::Notifier do
  it "is a Sorbet interface module" do
    expect(described_class).to be_a(Module)
  end

  it "declares notify_new_scene as an abstract method" do
    expect(described_class.instance_method(:notify_new_scene)).not_to be_nil
  end

  it "declares notify_scene_resolved as an abstract method" do
    expect(described_class.instance_method(:notify_scene_resolved)).not_to be_nil
  end

  it "declares notify_post_digest as an abstract method" do
    expect(described_class.instance_method(:notify_post_digest)).not_to be_nil
  end

  it "raises NotImplementedError when abstract methods are called without an implementation" do
    impl = Class.new { include Ports::Notifier }.new
    expect { impl.notify_new_scene(scene: nil, recipient: nil) }.to raise_error(NotImplementedError)
  end
end
