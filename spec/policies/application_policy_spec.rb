require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:user) { build_stubbed(:user) }
  let(:record) { double("record") }

  subject(:policy) { described_class.new(user, record) }

  describe "#initialize" do
    it "exposes the user and record it was built with" do
      expect(policy.user).to eq(user)
      expect(policy.record).to eq(record)
    end
  end

  describe "default-deny queries" do
    it { expect(policy.index?).to be(false) }
    it { expect(policy.show?).to be(false) }
    it { expect(policy.create?).to be(false) }
    it { expect(policy.new?).to be(false) }
    it { expect(policy.update?).to be(false) }
    it { expect(policy.edit?).to be(false) }
    it { expect(policy.destroy?).to be(false) }
  end

  # new? and edit? must delegate to create?/update? — not return a hard-coded
  # false — so an overriding subclass inherits the alias for free.
  describe "aliases follow their target" do
    let(:permissive) do
      Class.new(ApplicationPolicy) do
        def create? = true
        def update? = true
      end
    end

    subject(:policy) { permissive.new(user, record) }

    it "new? mirrors create?" do
      expect(policy.new?).to be(true)
    end

    it "edit? mirrors update?" do
      expect(policy.edit?).to be(true)
    end
  end

  describe ApplicationPolicy::Scope do
    let(:relation) { double("scope") }

    subject(:scope) { described_class.new(user, relation) }

    it "#resolve is abstract, naming the concrete subclass" do
      expect { scope.resolve }
        .to raise_error(NoMethodError, /must define #resolve in ApplicationPolicy::Scope/)
    end

    it "retains the user and scope for subclasses to read" do
      reader = Class.new(ApplicationPolicy::Scope) do
        def resolve = [ user, scope ]
      end
      expect(reader.new(user, relation).resolve).to eq([ user, relation ])
    end
  end
end
