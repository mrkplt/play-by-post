require "rails_helper"

RSpec.describe Shared::GameFlagToggle do
  # A minimal includer, so the module is tested for its own behaviour rather
  # than through either toggle component's presentation. Named rather than an
  # anonymous Class.new — an anonymous class's `initialize` is defined on Object
  # as far as Sorbet is concerned, which breaks unrelated call sites.
  class TestToggle
    include Shared::GameFlagToggle

    def initialize(on:)
      @on = on
    end

    def on? = @on
    def on_label = "Turn Off"
    def off_label = "Turn On"
  end

  it "shows the on_label when the flag is on (the button turns it off)" do
    expect(TestToggle.new(on: true).toggle_label).to eq("Turn Off")
  end

  it "shows the off_label when the flag is off (the button turns it on)" do
    expect(TestToggle.new(on: false).toggle_label).to eq("Turn On")
  end
end
