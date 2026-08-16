# typed: false
# frozen_string_literal: true

# Helper for the pundit_symbolic tool specs. Uses the project's rails_helper so
# the policies load in their real environment (real model constants, sigs
# already evaluated) — the same way every other spec here runs. This avoids
# mutating global sorbet config or stubbing model constants at load time, which
# poisoned the shared suite when all specs load together (e.g. under mutant).
require "rails_helper"

lib = File.expand_path("../../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
