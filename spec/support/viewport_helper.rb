module ViewportHelper
  # The two viewport modes the responsive layout targets. Feature specs that
  # assert size-independent invariants (no horizontal scroll, readable text,
  # touch targets, contained images) iterate over these so the same behaviour
  # is verified on a phone and on a desktop browser. The nav chrome itself
  # differs by size and is covered separately (mobile_nav_spec / desktop_nav_spec).
  VIEWPORTS = {
    "mobile (375px)" => [375, 812],
    "desktop (1280px)" => [1280, 900]
  }.freeze

  def resize_window_to_viewport(width, height)
    page.driver.resize_window_to(page.driver.current_window_handle, width, height)
  end
end

RSpec.configure do |config|
  config.include ViewportHelper, type: :feature
end
