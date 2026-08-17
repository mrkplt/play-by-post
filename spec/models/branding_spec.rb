require "rails_helper"

RSpec.describe Branding do
  describe ".display_name" do
    # APP_NAME is a human display name — it may contain spaces and is never a
    # hostname. "Flail Whale" (this deployment) exercises that.
    it "reads APP_NAME verbatim, spaces and all" do
      stub_env("APP_NAME", "Flail Whale") do
        expect(described_class.display_name).to eq("Flail Whale")
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

    # Regression: the URL comes from APP_HOST only. A spaced display name
    # ("Flail Whale") must never leak into a URL — the host stays clean.
    it "derives the URL from APP_HOST, never from a spaced APP_NAME" do
      stub_env("APP_NAME", "Flail Whale") do
        stub_env("APP_HOST", "flailwhale.com") do
          expect(described_class.url).to eq("https://flailwhale.com")
        end
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
