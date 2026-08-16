# typed: false
# frozen_string_literal: true

require_relative "spec_helper"
require "pundit_symbolic/invariants"

RSpec.describe PunditSymbolic::Invariants do
  def check(entry, formulas)
    described_class.check(entry, formulas)
  end

  let(:a) { var("a") }
  let(:b) { var("b") }

  describe "equivalent" do
    it "passes when the two formulas agree on every input" do
      expect(check({ "equivalent" => %w[x y] }, { "x" => a, "y" => a })).to be_nil
    end

    it "reports a violation with a description and witness when they disagree" do
      violation = check({ "equivalent" => %w[x y] }, { "x" => a, "y" => b })
      expect(violation.type).to eq("equivalent")
      expect(violation.description).to match(/declared equivalent but disagree/)
      expect(violation.model).to be_a(Hash)
    end
  end

  describe "implies" do
    it "passes when a ⇒ b holds" do
      expect(check({ "implies" => %w[x y] }, { "x" => conj(a, b), "y" => a })).to be_nil
    end

    it "reports a violation when a grants where b denies" do
      violation = check({ "implies" => %w[x y] }, { "x" => a, "y" => conj(a, b) })
      expect(violation.type).to eq("implies")
      expect(violation.description).to match(/grants where .* denies/)
    end
  end

  describe "mutually_exclusive" do
    it "passes when the two can never both hold" do
      expect(check({ "mutually_exclusive" => %w[x y] }, { "x" => a, "y" => negate(a) })).to be_nil
    end

    it "reports a violation when both can hold" do
      violation = check({ "mutually_exclusive" => %w[x y] }, { "x" => a, "y" => a })
      expect(violation.type).to eq("mutually_exclusive")
      expect(violation.description).to match(/mutually exclusive but can both hold/)
    end
  end

  describe "always / never" do
    it "always passes for a constant-true predicate" do
      expect(check({ "always" => "x" }, { "x" => const(true) })).to be_nil
    end

    it "always reports (with description) when the predicate can be false" do
      violation = check({ "always" => "x" }, { "x" => a })
      expect(violation.type).to eq("always")
      expect(violation.description).to match(/declared true for all inputs/)
    end

    it "never passes for a constant-false predicate" do
      expect(check({ "never" => "x" }, { "x" => const(false) })).to be_nil
    end

    it "never reports when the predicate can be true" do
      expect(check({ "never" => "x" }, { "x" => a }).type).to eq("never")
    end
  end

  describe "no_status_blind_grant" do
    let(:role) { var("record.member_for.game_master?") }
    let(:active) { var("record.member_for.active?") }

    it "passes when the predicate reads no game_master role leaf" do
      expect(check({ "no_status_blind_grant" => "x" }, { "x" => a })).to be_nil
    end

    it "passes when the grant requires active membership (status-aware)" do
      expect(check({ "no_status_blind_grant" => "x" }, { "x" => active })).to be_nil
    end

    it "reports (with witness) when the role leaf alone carries the grant" do
      violation = check({ "no_status_blind_grant" => "x" }, { "x" => disj(role, active) })
      expect(violation.type).to eq("no_status_blind_grant")
      expect(violation.model).to include("record.member_for.game_master?" => true)
    end
  end

  describe "bad declarations" do
    it "raises on an unknown invariant type" do
      expect { check({ "nonsense" => "x" }, {}) }.to raise_error(described_class::BadDeclaration, /unknown invariant type/)
    end

    it "raises when an entry is not a single-key mapping" do
      expect { check({ "a" => 1, "b" => 2 }, {}) }.to raise_error(described_class::BadDeclaration, /single-key/)
    end

    it "raises when an invariant names a predicate the policy lacks" do
      expect { check({ "equivalent" => %w[x y] }, { "x" => a }) }.to raise_error(described_class::BadDeclaration, /not an encodable predicate/)
    end
  end
end
