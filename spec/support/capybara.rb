require "capybara/playwright"

Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
Capybara.server = :puma, { Silent: true }

# Ui::ButtonComponent's link path sets role="button" on non-GET action links
# (Export Game, Remove/Ban, ...) so they read and test the same as a real
# <button> — enable the :button selector's aria-role check to honor it.
Capybara.enable_aria_role = true

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: true,
    playwright_server_timeout: 60
  )
end
