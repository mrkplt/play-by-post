# Assertions for the universal-header nav affordances (Fizzy #55): the
# hamburger, the active secondary-nav tab, and the breadcrumb link. Used from
# request specs — parses response.body with Capybara's node-less HTML parser
# so specs can assert with CSS instead of raw string matching.
#
# These affordances are size-independent invariants (see CLAUDE.md Path 1/2/3
# rules for responsive testing) — assert them once per converted page at the
# request-spec level, not per-viewport.
module NavAffordanceHelper
  def page_node
    Capybara::Node::Simple.new(response.body)
  end

  def expect_hamburger_present
    expect(page_node).to have_css("[data-action='click->sidebar#open']")
  end

  def expect_active_tab(label)
    expect(page_node).to have_css("[data-tab], a", text: label)
    expect(page_node).to have_css(".bg-accent", text: label)
  end

  def expect_breadcrumb(game_name)
    expect(page_node).to have_css("nav[aria-label='Breadcrumb']", text: game_name)
  end
end

RSpec.configure do |config|
  config.include NavAffordanceHelper, type: :request
end
