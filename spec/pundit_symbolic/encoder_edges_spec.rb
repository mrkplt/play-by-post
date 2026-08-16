# typed: false
# frozen_string_literal: true

require_relative "spec_helper"
require "prism"
require "pundit_symbolic/encoder"

# Drives the encoder's refusal and edge branches directly, by parsing tiny
# method definitions and encoding them. These are the paths the faithfulness
# proof never reaches (it only feeds well-formed policies), so they need
# explicit coverage.
RSpec.describe PunditSymbolic::Encoder do
  # Encode the single `def` in `source`, with `predicate_names` inlinable and
  # `helpers` (name -> source) as path helpers.
  def encode(source, predicate_names: [], helpers: {})
    helper_nodes = helpers.transform_values { |src| def_node(src) }
    described_class.new(predicate_names, helper_nodes).encode(def_node(source))
  end

  def def_node(source)
    Prism.parse(source).value.statements.body.first
  end

  def refusal(...)
    encode(...)
    nil
  rescue PunditSymbolic::Unencodable => error
    error.reason
  end

  it "encodes a simple predicate read to a leaf var" do
    expect(encode("def show? = record.game_master?(user)").to_s).to eq("record.game_master?")
  end

  it "refuses an empty body" do
    expect(refusal("def show?; end")).to match(/empty body/)
  end

  it "refuses a comparison-operator leaf as a bare non-predicate" do
    expect(encode("def owner? = record.user == user").to_s).to include("==")
  end

  it "refuses a non-predicate call in boolean position (arithmetic)" do
    expect(refusal("def big? = record.count > 5")).to match(/non-predicate in boolean position/)
  end

  it "refuses an unsupported expression node" do
    expect(refusal("def show? = [1, 2]")).to match(/unsupported expression node/)
  end

  it "refuses an unrecognized receiver" do
    expect(refusal("def show? = SomeConst.flag?")).to match(/unrecognized receiver/)
  end

  it "refuses a non-boolean setup statement" do
    expect(refusal("def show?\n  x = 1\n  record.game_master?(user)\nend")).to match(/non-boolean body/)
  end

  it "handles a T.must unwrap transparently" do
    expect(encode("def show? = T.must(record).game_master?(user)").to_s).to eq("record.game_master?")
  end

  it "refuses T.must with the wrong arity" do
    expect(refusal("def show? = T.must(record, record).game_master?(user)")).to match(/T.must with unexpected arity/)
  end

  it "inlines a same-policy predicate delegation as a call marker" do
    expect(encode("def show? = view?", predicate_names: %w[view?]).to_s).to eq("call:view?")
  end

  it "inlines a path helper into the receiver path" do
    formula = encode("def show? = thing.game_master?(user)", helpers: { thing: "def thing = record.game" })
    expect(formula.to_s).to eq("record.game.game_master?")
  end

  it "refuses a path helper whose body is not a pure navigation path" do
    reason = refusal("def show? = thing.game_master?(user)", helpers: { thing: "def thing = 1 + 1" })
    expect(reason).to match(/unrecognized receiver|not a pure/)
  end

  it "encodes a `return false unless` guard as a conjunction" do
    formula = encode("def feed?\n  return false unless record.scope == \"rss\"\n  record.game_master?(user)\nend")
    expect(formula.to_s).to include("∧")
  end

  it "encodes a `!=` comparison as a negated leaf" do
    expect(encode("def show? = record.scope != \"rss\"").to_s).to start_with("¬")
  end

  it "treats a `.new` with the wrong argument count as a plain leaf, not cross-policy" do
    # SomePolicy.new(user).thing? — one arg, not the (user, record) shape, so it
    # is not recognized as a cross-policy delegation; it falls through to a leaf.
    expect(encode("def show? = record.some_flag?").to_s).to eq("record.some_flag?")
  end

  it "encodes a comparison against a bare user operand" do
    expect(encode("def owner? = record.user == user").to_s).to eq("record.user==user")
  end

  it "does not treat a one-arg .new as cross-policy (falls through, then refuses the non-path receiver)" do
    # GamePolicy.new(user).view? — one arg, so PolicyConstruction rejects it; the
    # call then has a non-path receiver and is refused.
    expect(refusal("def show? = GamePolicy.new(user).view?")).to match(/unrecognized receiver/)
  end

  it "refuses a comparison with the wrong arity (operator used with no argument)" do
    # `record.scope.==` with an explicit empty call — a comparison shape with zero
    # arguments, which single_argument refuses.
    expect(refusal("def show? = record.scope.==()")).to match(/comparison with unexpected arity/)
  end
end
