# typed: false
# frozen_string_literal: true

require_relative "spec_helper"
require "tmpdir"
require "pundit_symbolic/policy_registry"

RSpec.describe PunditSymbolic::PolicyRegistry do
  # Write `policies` (name => body source) into a temp dir and load a registry.
  def registry_for(policies)
    Dir.mktmpdir do |dir|
      policies.each do |name, body|
        file = File.join(dir, "#{name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}.rb")
        File.write(file, "class #{name}\n#{body}\nend\n")
      end
      yield described_class.load_dir(dir)
    end
  end

  def predicate(source, name)
    source.predicates.find { |p| p.name == name }
  end

  it "resolves a cross-policy delegation by rebasing the target's leaves" do
    policies = {
      "TargetPolicy" => "  def view? = record.viewable_by?(user)",
      "HostPolicy" => "  def show? = TargetPolicy.new(user, record.game).view?"
    }
    registry_for(policies) do |registry|
      host = registry.sources.find { |s| s.policy_name == "HostPolicy" }
      expect(predicate(host, "show?").formula.to_s).to eq("record.game.viewable_by?")
    end
  end

  it "refuses a delegation whose target predicate does not exist" do
    policies = {
      "TargetPolicy" => "  def view? = record.viewable_by?(user)",
      "HostPolicy" => "  def show? = TargetPolicy.new(user, record.game).missing?"
    }
    registry_for(policies) do |registry|
      host = registry.sources.find { |s| s.policy_name == "HostPolicy" }
      expect(predicate(host, "show?")).to be_nil
      expect(host.refusals.map { |r| r[:name] }).to include("show?")
      expect(host.refusals.first[:reason]).to match(/unresolvable cross-policy/)
    end
  end

  it "refuses a delegation to a policy that isn't loaded" do
    policies = { "HostPolicy" => "  def show? = MissingPolicy.new(user, record.game).view?" }
    registry_for(policies) do |registry|
      host = registry.sources.first
      expect(predicate(host, "show?")).to be_nil
      expect(host.refusals.map { |r| r[:name] }).to include("show?")
    end
  end
end
