require "rails_helper"

RSpec.describe NotebookEntryVersion do
  describe "associations" do
    it "belongs to a notebook entry" do
      expect(described_class.reflect_on_association(:notebook_entry).macro).to eq(:belongs_to)
    end

    it "belongs to the editing user" do
      association = described_class.reflect_on_association(:edited_by)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq("User")
    end
  end
end
