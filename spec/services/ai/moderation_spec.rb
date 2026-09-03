# typed: false

require "rails_helper"

# Ai::Moderation fetches the OpenAI moderation result and hands (prompt, result)
# to each injected rule, aggregating their outcomes. Rules are injected here so
# the aggregation is tested in isolation from which concrete rules exist; each
# concrete rule has its own spec. The real #connection runs against Faraday's
# test adapter.
RSpec.describe Ai::Moderation do
  let(:stubs) { "Faraday::Adapter::Test::Stubs".constantize.new }

  # A fake rule (a module-like object responding to #moderate) returning a fixed
  # outcome, and recording what it was moderated with.
  def fake_rule(moderated:, reason: "", captured: {})
    rule = double("Rule")
    allow(rule).to receive(:moderate) do |prompt, result|
      captured[:prompt] = prompt
      captured[:result] = result
      Ai::Moderation::Rule::Outcome.new(moderated: moderated, reason: reason)
    end
    rule
  end

  def moderation(rules:)
    described_class.new(api_key: "app-key", adapter: [ :test, stubs ], rules: rules)
  end

  def stub_moderation_api(result_entry, captured: {})
    stubs.post("https://api.openai.com/v1/moderations") do |env|
      captured[:authorization] = env.request_headers["Authorization"]
      captured[:body] = env.body
      [ 200, { "Content-Type" => "application/json" }, JSON.generate("results" => [ result_entry ]) ]
    end
  end

  describe "#call" do
    it "posts the model and input with the app bearer key" do
      captured = {}
      stub_moderation_api({ "flagged" => false }, captured: captured)

      moderation(rules: []).call("a knight")

      expect(captured[:authorization]).to eq("Bearer app-key")
      expect(JSON.parse(captured[:body])).to eq("model" => "test/moderation-model", "input" => "a knight")
    end

    it "passes the prompt and the parsed result entry to each rule" do
      captured = {}
      stub_moderation_api({ "flagged" => true, "categories" => { "sexual" => true } })
      rule = fake_rule(moderated: false, captured: captured)

      moderation(rules: [ rule ]).call("a knight")

      expect(captured[:prompt]).to eq("a knight")
      expect(captured[:result]).to eq("flagged" => true, "categories" => { "sexual" => true })
    end

    it "is unflagged when no rule moderates" do
      stub_moderation_api({ "flagged" => false })

      verdict = moderation(rules: [ fake_rule(moderated: false), fake_rule(moderated: false) ]).call("ok")

      expect(verdict.flagged?).to be(false)
      expect(verdict.reasons).to be_empty
    end

    it "is flagged when any rule moderates, collecting every blocking reason" do
      stub_moderation_api({ "flagged" => true })
      rules = [
        fake_rule(moderated: true, reason: "rule A"),
        fake_rule(moderated: false, reason: "should be ignored"),
        fake_rule(moderated: true, reason: "rule B")
      ]

      verdict = moderation(rules: rules).call("bad")

      expect(verdict.flagged?).to be(true)
      expect(verdict.reasons).to contain_exactly("rule A", "rule B")
    end

    it "gives rules an empty result hash when the response has no results" do
      captured = {}
      stubs.post("https://api.openai.com/v1/moderations") do |_env|
        [ 200, { "Content-Type" => "application/json" }, JSON.generate({}) ]
      end
      rule = fake_rule(moderated: false, captured: captured)

      moderation(rules: [ rule ]).call("x")

      expect(captured[:result]).to eq({})
    end

    it "lets a transport error propagate so the caller can fail closed" do
      stubs.post("https://api.openai.com/v1/moderations") do |_env|
        [ 500, {}, JSON.generate("error" => "server") ]
      end

      expect { moderation(rules: []).call("x") }.to raise_error(Faraday::Error)
    end
  end

  describe "#default_rules (runtime discovery)" do
    # Reference the concrete rules first so they are loaded (app/services is
    # autoloaded, not eager-loaded in isolation), so Rules.constants sees them —
    # then assert discovery returns every rule module.
    it "discovers every rule module under Rules" do
      expected = [ Ai::Moderation::Rules::FlaggedCategories, Ai::Moderation::Rules::MinorSafety ]

      discovered = described_class.new(api_key: "k").send(:default_rules)

      expect(discovered).to include(*expected)
      expect(discovered).to all(respond_to(:moderate))
    end
  end
end
