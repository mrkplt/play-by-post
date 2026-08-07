require "rails_helper"

RSpec.describe GameLink do
  describe "associations" do
    it "belongs to a game" do
      expect(described_class.reflect_on_association(:game).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires a description" do
      link = build(:game_link, description: nil)
      expect(link).not_to be_valid
      expect(link.errors[:description]).to be_present
    end

    it "rejects a description longer than 200 characters" do
      link = build(:game_link, description: "a" * 201)
      expect(link).not_to be_valid
      expect(link.errors[:description]).to be_present
    end

    it "accepts a description of exactly 200 characters" do
      link = build(:game_link, description: "a" * 200)
      expect(link.errors[:description]).to be_empty
    end

    it "requires a url" do
      link = build(:game_link, url: nil)
      expect(link).not_to be_valid
      expect(link.errors[:url]).to be_present
    end

    it "reports a blank url as missing, not as malformed" do
      link = build(:game_link, url: "")
      link.valid?
      expect(link.errors[:url]).not_to include("must be a valid http(s) URL")
    end
  end

  describe "URL validation" do
    it "accepts an absolute http URL" do
      link = build(:game_link, url: "http://example.com/wiki")
      link.valid?
      expect(link.errors[:url]).to be_empty
    end

    it "accepts an absolute https URL" do
      link = build(:game_link, url: "https://example.com")
      link.valid?
      expect(link.errors[:url]).to be_empty
    end

    it "rejects a scheme-less URL" do
      link = build(:game_link, url: "example.com/wiki")
      link.valid?
      expect(link.errors[:url]).to include("must be a valid http(s) URL")
    end

    it "rejects a javascript: URL" do
      link = build(:game_link, url: "javascript:alert(1)")
      link.valid?
      expect(link.errors[:url]).to include("must be a valid http(s) URL")
    end

    it "rejects a non-web scheme" do
      link = build(:game_link, url: "ftp://example.com/file")
      link.valid?
      expect(link.errors[:url]).to include("must be a valid http(s) URL")
    end

    it "rejects an unparseable URL" do
      link = build(:game_link, url: "not a url")
      link.valid?
      expect(link.errors[:url]).to include("must be a valid http(s) URL")
    end

    it "rejects a URL with no host" do
      link = build(:game_link, url: "https://")
      link.valid?
      expect(link.errors[:url]).to include("must be a valid http(s) URL")
    end
  end
end
