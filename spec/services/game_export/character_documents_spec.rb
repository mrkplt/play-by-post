require "rails_helper"

RSpec.describe GameExport::CharacterDocuments, :db do
  describe "#character_sheet_content" do
    let(:service) { described_class.new(build_stubbed(:user), []) }

    def sheet(character)
      GameExport::CharacterDocuments.sheet(character)
    end

    it "notes a hidden character" do
      expect(sheet(build_stubbed(:character, :hidden))).to include("**Hidden:** Yes")
    end

    it "notes an archived character" do
      expect(sheet(build_stubbed(:character, :archived))).to include("**Archived:** Yes")
    end

    it "notes an ordinary character as neither" do
      content = sheet(build_stubbed(:character))

      expect(content).to include("**Hidden:** No")
      expect(content).to include("**Archived:** No")
    end
  end
end
