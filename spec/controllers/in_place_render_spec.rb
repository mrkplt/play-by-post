require "rails_helper"

# Unit-tests the InPlaceRender controller module against a host double, the same
# technique as spec/services/in_place_save_spec.rb (a real class body would
# register its #initialize as Object#initialize for Sorbet). Exercises each
# method's logic directly so its mutants die here rather than relying on coarse
# request-spec assertions.
RSpec.describe InPlaceRender do
  # A flash whose #now writes are visible through #[] under string keys, the way
  # ActionDispatch's flash exposes flash.now values to FlashPresenter (which reads
  # flash["notice"]/flash["alert"]).
  def flash_spy
    flash = Object.new
    store = {}
    flash.define_singleton_method(:now) { store }
    flash.define_singleton_method(:[]) { |key| store[key] || store[key.to_sym] }
    flash
  end

  # A turbo_stream double recording every replace(target, *rest) call.
  def turbo_stream_spy
    ts = Object.new
    calls = []
    ts.define_singleton_method(:replace) do |target, arg = nil, **opts|
      calls << { target: target, arg: arg, opts: opts }
      "<turbo-stream replace #{target}>"
    end
    ts.define_singleton_method(:calls) { calls }
    ts
  end

  def host(flash: flash_spy, turbo_stream: turbo_stream_spy)
    obj = Object.new.extend(described_class)
    helpers = Object.new
    helpers.define_singleton_method(:turbo_stream) { turbo_stream }
    obj.define_singleton_method(:flash) { flash }
    obj.define_singleton_method(:helpers) { helpers }
    obj
  end

  describe "#flash_now" do
    it "writes only the notice when only a notice is given" do
      flash = flash_spy
      host(flash: flash).send(:flash_now, notice: "Saved.")
      expect(flash.now).to eq(notice: "Saved.")
    end

    it "writes only the alert when only an alert is given" do
      flash = flash_spy
      host(flash: flash).send(:flash_now, alert: "Nope.")
      expect(flash.now).to eq(alert: "Nope.")
    end

    it "writes both when both are given" do
      flash = flash_spy
      host(flash: flash).send(:flash_now, notice: "Saved.", alert: "But…")
      expect(flash.now).to eq(notice: "Saved.", alert: "But…")
    end

    it "writes nothing when neither is given" do
      flash = flash_spy
      host(flash: flash).send(:flash_now)
      expect(flash.now).to be_empty
    end
  end

  describe "#toast_stream" do
    it "replaces the toast target with a toast component built from the flash" do
      ts = turbo_stream_spy
      flash = flash_spy
      flash.now[:notice] = "Done."
      host(flash: flash, turbo_stream: ts).send(:toast_stream)

      call = ts.calls.fetch(0)
      expect(call[:target]).to eq(InPlaceRender::TOAST_TARGET)
      expect(call[:arg]).to be_a(Ui::ToastComponent)
      expect(call[:arg].toasts).to eq([ { message: "Done.", variant: :success } ])
    end
  end

  describe "#game_controls_stream" do
    it "replaces #game_controls with the profiles/game_controls partial for the user" do
      ts = turbo_stream_spy
      user = create(:user, :with_profile)
      host(turbo_stream: ts).send(:game_controls_stream, user)

      call = ts.calls.fetch(0)
      expect(call[:target]).to eq("game_controls")
      expect(call[:opts][:partial]).to eq("profiles/game_controls")
      presenter = call[:opts][:locals][:user_presenter]
      expect(presenter).to be_a(UserPresenter)
      # The presenter wraps THIS user (kills UserPresenter.new(nil) / wrong arg).
      expect(presenter.id).to eq(user.id)
    end
  end

  describe "#turbo_or_redirect" do
    # A respond_to collector that runs only the chosen format's block.
    def respond_host(format:)
      obj = host
      state = { rendered: nil, redirect: nil }
      obj.define_singleton_method(:state) { state }
      obj.define_singleton_method(:redirect_to) { |path, alert:| state[:redirect] = { path: path, alert: alert } }
      obj.define_singleton_method(:respond_to) do |&blk|
        collector = Object.new
        collector.define_singleton_method(:turbo_stream) { |&b| b&.call if format == :turbo_stream }
        collector.define_singleton_method(:html) { |&b| b.call if format == :html }
        blk.call(collector)
      end
      [ obj, state ]
    end

    it "runs the turbo_stream block for a Turbo request and does not redirect" do
      obj, state = respond_host(format: :turbo_stream)
      ran = false
      obj.send(:turbo_or_redirect, fallback: "/back") { ran = true }
      expect(ran).to be(true)
      expect(state[:redirect]).to be_nil
    end

    it "redirects to the fallback (with the alert) for a non-Turbo request" do
      obj, state = respond_host(format: :html)
      obj.send(:turbo_or_redirect, fallback: "/back", alert: "bad") { raise "should not run" }
      expect(state[:redirect]).to eq(path: "/back", alert: "bad")
    end
  end
end
