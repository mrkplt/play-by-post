# typed: false

require "rails_helper"

RSpec.describe RuntimeMode do
  describe ".value" do
    it "is nil when RUNTIME_MODE is unset" do
      stub_env("RUNTIME_MODE", nil) do
        expect(described_class.value).to be_nil
      end
    end

    it "is nil when RUNTIME_MODE is blank (blank normalises to unset)" do
      stub_env("RUNTIME_MODE", "") do
        expect(described_class.value).to be_nil
      end
    end

    it "returns the configured value verbatim" do
      stub_env("RUNTIME_MODE", "api") do
        expect(described_class.value).to eq("api")
      end
    end
  end

  describe ".web?" do
    it "is true when unset (default draws everything)" do
      stub_env("RUNTIME_MODE", nil) do
        expect(described_class.web?).to be(true)
      end
    end

    it "is true in web mode" do
      stub_env("RUNTIME_MODE", "web") do
        expect(described_class.web?).to be(true)
      end
    end

    it "is false in api mode" do
      stub_env("RUNTIME_MODE", "api") do
        expect(described_class.web?).to be(false)
      end
    end

    it "is false for an unrecognised value" do
      stub_env("RUNTIME_MODE", "nonsense") do
        expect(described_class.web?).to be(false)
      end
    end
  end

  describe ".api?" do
    it "is true when unset (default draws everything)" do
      stub_env("RUNTIME_MODE", nil) do
        expect(described_class.api?).to be(true)
      end
    end

    it "is true in api mode" do
      stub_env("RUNTIME_MODE", "api") do
        expect(described_class.api?).to be(true)
      end
    end

    it "is false in web mode" do
      stub_env("RUNTIME_MODE", "web") do
        expect(described_class.api?).to be(false)
      end
    end

    it "is false for an unrecognised value" do
      stub_env("RUNTIME_MODE", "nonsense") do
        expect(described_class.api?).to be(false)
      end
    end
  end

  describe ".all?" do
    it "is true only when unset" do
      stub_env("RUNTIME_MODE", nil) do
        expect(described_class.all?).to be(true)
      end
    end

    it "is false in web mode" do
      stub_env("RUNTIME_MODE", "web") do
        expect(described_class.all?).to be(false)
      end
    end

    it "is false in api mode" do
      stub_env("RUNTIME_MODE", "api") do
        expect(described_class.all?).to be(false)
      end
    end
  end

  # Sets ENV[key] for the block and restores the prior value after — never
  # leaks a mutated global into another example (see CLAUDE.md testing notes).
  def stub_env(key, value)
    original = ENV.fetch(key, nil)
    value.nil? ? ENV.delete(key) : ENV[key] = value
    yield
  ensure
    original.nil? ? ENV.delete(key) : ENV[key] = original
  end
end
