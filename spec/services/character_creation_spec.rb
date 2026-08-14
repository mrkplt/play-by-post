require "rails_helper"

RSpec.describe CharacterCreation, :db do
  def build_params(hash)
    ActionController::Parameters.new(hash)
  end

  let(:game) { create(:game) }
  let(:character) { game.characters.new }
  let(:current_user) { create(:user) }
  let(:character_policy) { CharacterPolicy.new(current_user, character) }

  describe "#call" do
    context "when the viewer may not assign an owner (an ordinary player)" do
      before { allow(character_policy).to receive(:assign_owner?).and_return(false) }

      it "assigns the character to the current user and saves" do
        creation = described_class.new(character, character_policy, build_params(character: { name: "Vex" }))

        expect(creation.call(current_user)).to be(true)
        expect(character.user).to eq(current_user)
        expect(character.name).to eq("Vex")
      end
    end

    context "when the viewer may assign an owner (a GM)" do
      before { allow(character_policy).to receive(:assign_owner?).and_return(true) }

      let(:owner) { create(:user) }

      it "assigns the selected player as owner and saves" do
        params = build_params(character: { name: "Vex", user_id: owner.id.to_s })

        creation = described_class.new(character, character_policy, params)

        expect(creation.call(current_user)).to be(true)
        expect(character.user).to eq(owner)
      end

      it "adds a validation error and reports failure when no player was selected" do
        params = build_params(character: { name: "Vex", user_id: "" })
        creation = described_class.new(character, character_policy, params)

        expect(creation.call(current_user)).to be(false)
        expect(character.errors[:base]).to include("Please select a player")
      end
    end
  end
end
