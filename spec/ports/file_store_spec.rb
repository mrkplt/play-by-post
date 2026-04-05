# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ports::FileStore do
  it "is a Sorbet interface module" do
    expect(described_class).to be_a(Module)
  end

  it "declares attach as an abstract method" do
    expect(described_class.instance_method(:attach)).not_to be_nil
  end

  it "declares purge as an abstract method" do
    expect(described_class.instance_method(:purge)).not_to be_nil
  end

  it "raises NotImplementedError when abstract methods are called without an implementation" do
    impl = Class.new { include Ports::FileStore }.new
    expect { impl.attach(game_file: nil, upload: nil) }.to raise_error(NotImplementedError)
  end
end
