require "capybara/playwright"

Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
Capybara.server = :puma, { Silent: true }

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: true,
    playwright_server_timeout: 60
  )
end
