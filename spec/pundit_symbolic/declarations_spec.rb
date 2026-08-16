# typed: false
# frozen_string_literal: true

require_relative "spec_helper"
require "pundit_symbolic/declarations"

RSpec.describe PunditSymbolic::Declarations do
  let(:a) { var("a") }
  let(:formulas) { { "show?" => a, "view?" => a } }

  def declarations(raw)
    described_class.new(raw)
  end

  describe "#verify" do
    it "reports a policy with no declaration as missing" do
      result = declarations({}).verify("GamePolicy", formulas)
      expect(result.undeclared?).to be(true)
      expect(result.ok?).to be(false)
    end

    it "passes a declared policy whose invariants hold and predicates match" do
      raw = { "GamePolicy" => { "invariants" => [ { "equivalent" => %w[show? view?] } ], "unconstrained" => [] } }
      result = declarations(raw).verify("GamePolicy", formulas)
      expect(result).to be_ok
      expect(result.drift_errors).to be_empty
      expect(result.violations).to be_empty
    end

    it "treats an `unconstrained` predicate as accounted for (no drift)" do
      raw = { "GamePolicy" => { "unconstrained" => %w[show? view?] } }
      expect(declarations(raw).verify("GamePolicy", formulas).drift_errors).to be_empty
    end

    it "reports drift for a predicate with no declaration" do
      raw = { "GamePolicy" => { "unconstrained" => %w[show?] } } # view? unaccounted
      errors = declarations(raw).verify("GamePolicy", formulas).drift_errors
      expect(errors).to include(a_string_matching(/`view\?` has no declaration/))
    end

    it "reports drift for a stale declaration entry" do
      raw = { "GamePolicy" => { "unconstrained" => %w[show? view? gone?] } }
      errors = declarations(raw).verify("GamePolicy", formulas).drift_errors
      expect(errors).to include(a_string_matching(/`gone\?`.*not a public encodable predicate/))
    end

    it "does not run invariants while there is drift (drift masks violations)" do
      # `edit?` exists in the code but is unaccounted for -> drift; the declared
      # mutually_exclusive would otherwise fail, but drift short-circuits it.
      formulas_with_extra = formulas.merge("edit?" => a)
      raw = { "GamePolicy" => { "invariants" => [ { "mutually_exclusive" => %w[show? view?] } ], "unconstrained" => [] } }
      result = declarations(raw).verify("GamePolicy", formulas_with_extra)
      expect(result.drift_errors).not_to be_empty
      expect(result.violations).to be_empty
    end

    it "reports a violated invariant when predicates match" do
      raw = { "GamePolicy" => { "invariants" => [ { "mutually_exclusive" => %w[show? view?] } ], "unconstrained" => [] } }
      result = declarations(raw).verify("GamePolicy", formulas)
      expect(result.violations.map(&:type)).to eq([ "mutually_exclusive" ])
    end
  end

  describe ".load" do
    it "reads the contract from a YAML file" do
      require "tempfile"
      Tempfile.create([ "contract", ".yml" ]) do |file|
        file.write("GamePolicy:\n  unconstrained: [show?, view?]\n")
        file.flush
        loaded = described_class.load(file.path)
        expect(loaded.declared?("GamePolicy")).to be(true)
        expect(loaded.declared?("Missing")).to be(false)
      end
    end
  end
end
