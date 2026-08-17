require "rails_helper"

RSpec.describe Branding do
  describe ".display_name" do
    it "reads APP_NAME" do
      stub_env("APP_NAME", "flailwhale.com") do
        expect(described_class.display_name).to eq("flailwhale.com")
      end
    end

    it "falls back to the open-source default when APP_NAME is unset" do
      stub_env("APP_NAME", nil) do
        expect(described_class.display_name).to eq("Play by Post")
      end
    end
  end

  describe ".host" do
    it "reads APP_HOST" do
      stub_env("APP_HOST", "flailwhale.com") do
        expect(described_class.host).to eq("flailwhale.com")
      end
    end

    it "falls back to the open-source default when APP_HOST is unset" do
      stub_env("APP_HOST", nil) do
        expect(described_class.host).to eq("play-by-post.example.com")
      end
    end
  end

  describe ".url" do
    it "is https over the configured host" do
      stub_env("APP_HOST", "flailwhale.com") do
        expect(described_class.url).to eq("https://flailwhale.com")
      end
    end

    it "uses the default host over https when APP_HOST is unset" do
      stub_env("APP_HOST", nil) do
        expect(described_class.url).to eq("https://play-by-post.example.com")
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
