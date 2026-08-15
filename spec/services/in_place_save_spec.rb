require "rails_helper"

RSpec.describe InPlaceSave do
  # Test doubles rather than classes: defining a class body here (even via
  # Class.new) registers its #initialize as Object#initialize for Sorbet, which
  # then reports errors in unrelated app code.
  def flash_spy
    flash = Object.new
    store = {}
    flash.define_singleton_method(:now) { store }
    flash
  end

  # Runs only the block registered for the requested format, the way
  # ActionController's real collector picks one branch.
  def controller_spy(format:)
    controller = Object.new
    state = { flash: flash_spy, rendered: nil, redirected: nil }

    controller.define_singleton_method(:flash) { state[:flash] }
    controller.define_singleton_method(:state) { state }
    controller.define_singleton_method(:render) { |template, status:| state[:rendered] = { template: template, status: status } }
    controller.define_singleton_method(:redirect_to) { |path, notice:| state[:redirected] = { path: path, notice: notice } }
    controller.define_singleton_method(:respond_to) do |&block|
      collector = Object.new
      chosen = nil
      collector.define_singleton_method(:turbo_stream) { |&b| chosen = b if format == :turbo_stream }
      collector.define_singleton_method(:html) { |&b| chosen = b if format == :html }
      block.call(collector)
      chosen&.call
    end

    controller
  end

  def save_for(format:, saved:)
    controller = controller_spy(format: format)
    outcome = SaveOutcome.for(saved, "page")

    described_class.new(controller, outcome: outcome, forward_to: "/games/1/pages/x").respond
    controller
  end

  describe "a Turbo client" do
    it "renders the update stream" do
      controller = save_for(format: :turbo_stream, saved: true)

      expect(controller.state[:rendered]).to eq({ template: :update, status: :ok })
    end

    it "puts the confirmation in the flash for this response only" do
      controller = save_for(format: :turbo_stream, saved: true)

      expect(controller.flash.now).to eq({ notice: "Page updated." })
    end

    it "answers unprocessable with the failure message when the save failed" do
      controller = save_for(format: :turbo_stream, saved: false)

      expect(controller.state[:rendered]).to eq({ template: :update, status: :unprocessable_content })
      expect(controller.flash.now).to eq({ alert: "Could not save the page." })
    end

    it "never redirects" do
      expect(save_for(format: :turbo_stream, saved: true).state[:redirected]).to be_nil
    end
  end

  describe "a non-Turbo client" do
    it "forwards on success" do
      controller = save_for(format: :html, saved: true)

      expect(controller.state[:redirected]).to eq({ path: "/games/1/pages/x", notice: "Page updated." })
    end

    it "re-renders the form on failure" do
      controller = save_for(format: :html, saved: false)

      expect(controller.state[:rendered]).to eq({ template: :edit, status: :unprocessable_content })
    end

    it "does not redirect on failure" do
      expect(save_for(format: :html, saved: false).state[:redirected]).to be_nil
    end
  end
end
