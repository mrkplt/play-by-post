require "rails_helper"

RSpec.describe Shared::AsyncPendingComponent, type: :component do
  def pending(**overrides)
    described_class.new(
      frame_id: "thing_pending", poll_path: "/things/1/status", ready: false, **overrides
    )
  end

  describe "pending" do
    it "renders a turbo-frame whose poller carries the status path (no eager src)" do
      render_inline(pending)

      expect(page).to have_css("turbo-frame#thing_pending[data-job-status-src-value='/things/1/status']")
      expect(page).not_to have_css("turbo-frame#thing_pending[src]")
    end

    it "arms the poller on the frame with the given interval" do
      render_inline(pending(interval_ms: 1500))

      expect(page).to have_css(
        "turbo-frame#thing_pending[data-controller='job-status'][data-job-status-interval-value='1500']"
      )
    end

    it "defaults the poll interval to 3000ms" do
      render_inline(pending)

      expect(page).to have_css("turbo-frame#thing_pending[data-job-status-interval-value='3000']")
    end

    it "reports itself not ready" do
      expect(pending.ready?).to be(false)
    end

    it "shows a spinner and the waiting message" do
      render_inline(pending(message: "Working on it…"))

      expect(page).to have_text("Working on it…")
      expect(page).to have_css("turbo-frame#thing_pending span[role='status']")
    end

    it "defaults the waiting message" do
      render_inline(pending)

      expect(page).to have_text("Waiting…")
    end
  end

  describe "ready" do
    def ready_component
      described_class.new(frame_id: "thing_pending", poll_path: "/things/1/status", ready: true)
    end

    it "renders the ready slot content and drops both src and poller" do
      render_inline(ready_component) { |c| c.with_ready { "the finished thing" } }

      expect(page).to have_css("turbo-frame#thing_pending", text: "the finished thing")
      expect(page).not_to have_css("turbo-frame[src]")
      expect(page).not_to have_css("[data-controller='job-status']")
    end

    it "emits a bare frame with no data attributes once ready" do
      render_inline(ready_component) { |c| c.with_ready { "done" } }

      expect(page).to have_css("turbo-frame#thing_pending")
      expect(page).not_to have_css("turbo-frame[data-job-status-interval-value]")
      expect(page).not_to have_css("turbo-frame[data-job-status-src-value]")
    end

    it "shows no spinner once ready" do
      render_inline(ready_component) { |c| c.with_ready { "done" } }

      expect(page).not_to have_css("span[role='status']")
    end

    it "reports itself ready" do
      expect(ready_component.ready?).to be(true)
    end

    it "carries an empty frame-attributes hash once ready" do
      expect(ready_component.frame_attributes).to eq({})
    end
  end
end
