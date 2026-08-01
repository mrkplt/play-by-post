# typed: strict
# CI-DEMO: intentionally unregistered in .mutant.yml to fail mutant_registration.
class Ui::CiDemoComponent < ApplicationComponent
  extend T::Sig
  sig { void }
  def initialize; end
end
