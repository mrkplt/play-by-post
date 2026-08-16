# typed: false
# frozen_string_literal: true

# Standalone helper for the pundit_symbolic tool specs. These do NOT boot Rails:
# policies are pure (user, record) objects, so we load only sorbet-runtime and
# the policy classes under test. Keeps the faithfulness proof in the fast tier.
require "sorbet-runtime"

lib = File.expand_path("../../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# The faithfulness proof drives real policy methods with duck-typed doubles, so
# runtime sig checks (which assert e.g. a private helper returns a real `Scene`)
# would fail on the double, not on any logic under test. Turn sig enforcement
# off for these specs — we are proving the method BODIES, not their signatures.
T::Configuration.default_checked_level = :never

# Minimal stand-ins for the model constants some policy sigs name
# (`sig { returns(Scene) }`). With checks off these are never enforced, but the
# constants must resolve when the sig block evaluates. Defined only if absent so
# a real load (if one ever happens) wins.
%i[Scene Game].each do |const|
  Object.const_set(const, Class.new) unless Object.const_defined?(const)
end

# Load the policy base + every policy, standalone. Cross-policy delegations
# (CharacterVersionPolicy -> GamePolicy) need the target loaded, hence: load all.
policies = File.expand_path("../../app/policies", __dir__)
require File.join(policies, "application_policy")
Dir[File.join(policies, "*_policy.rb")].sort.each do |policy|
  require policy unless policy.end_with?("application_policy.rb")
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
