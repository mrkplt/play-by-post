# typed: false
# frozen_string_literal: true

# Standalone helper for the pundit_symbolic tool specs. These do NOT boot Rails:
# policies are pure (user, record) objects, so we load only sorbet-runtime and
# the policy classes under test. Keeps the faithfulness proof in the fast tier.
require "sorbet-runtime"

lib = File.expand_path("../../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Load the policy base + the policies the specs exercise, standalone.
policies = File.expand_path("../../app/policies", __dir__)
require File.join(policies, "application_policy")
require File.join(policies, "game_policy")

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
