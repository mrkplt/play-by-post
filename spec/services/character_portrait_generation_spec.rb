require "rails_helper"

# CharacterPortraitGeneration fills in a pending skeleton CharacterImage:
# compose -> moderate -> generate -> complete the skeleton, or fail it. The AI
# collaborators (Ai::Moderation, Ai::Funding) are stubbed so the pipeline is
# tested without HTTP or a live pool.
RSpec.describe CharacterPortraitGeneration do
  let!(:game) { create(:game) }
  let!(:player) { create(:user, :with_profile) }
  let!(:payer) { create(:user, :with_profile) }
  let!(:character) { create(:character, game: game, user: player) }
  # A pending skeleton: no file attached, not failed.
  let!(:image) { character.character_images.create! }

  let(:image_result) { Ai::ImageRequest::Result.new(png_bytes: "\x89PNG bytes".b, cost: 0.02) }
  let(:spend) { Ai::Funding::Spend.new(value: image_result, funded_by: payer) }

  def run
    described_class.new(image, player.id, "a grizzled dwarven smith").run
  end

  def stub_moderation(flagged:, reasons: [])
    verdict = Ai::Moderation::Verdict.new(flagged: flagged, reasons: reasons)
    allow(Ai::Moderation).to receive(:new).and_return(instance_double(Ai::Moderation, call: verdict))
  end

  def stub_funding(raises: nil)
    funding = instance_double(Ai::Funding)
    if raises
      allow(funding).to receive(:call).and_raise(raises)
    else
      allow(funding).to receive(:call).and_return(spend)
    end
    allow(Ai::Funding).to receive(:new).and_return(funding)
  end

  context "when the prompt passes moderation and generation succeeds" do
    before do
      stub_moderation(flagged: false)
      stub_funding
    end

    it "completes the skeleton: attaches the file and stamps provenance" do
      run
      image.reload

      expect(image.file).to be_attached
      expect(image.ai_generated?).to be(true)
      expect(image.pending?).to be(false)
    end

    it "does NOT make the generated image current (no auto-publish)" do
      run
      expect(image.reload.current).to be(false)
    end

    it "writes an AiGeneration audit row attributing requester and pooled payer" do
      expect { run }.to change(AiGeneration, :count).by(1)

      row = AiGeneration.last
      expect(row).to have_attributes(
        feature: "character_portrait", requested_by_id: player.id, funded_by_id: payer.id,
        asset_type: "CharacterImage", asset_id: image.id, cost: 0.02
      )
    end

    it "does not mark the skeleton failed" do
      run
      expect(image.reload.failed?).to be(false)
    end
  end

  context "when moderation flags the prompt" do
    before { stub_moderation(flagged: true, reasons: [ "flagged by moderation: sexual" ]) }

    it "fails the skeleton before spending a key (no funding, no image, no audit row)" do
      expect(Ai::Funding).not_to receive(:new)

      expect { run }.to change(AiGeneration, :count).by(0)
      expect(image.reload.file).not_to be_attached
    end

    it "records a player-facing moderation failure reason" do
      run
      expect(image.reload).to be_failed
      expect(image.failure_reason).to match(/blocked by content moderation/)
    end
  end

  context "when generation is refused by the image model" do
    before do
      stub_moderation(flagged: false)
      stub_funding(raises: Ai::ImageRequest::Refused.new("policy"))
    end

    it "fails the skeleton with a generic failure reason, no audit row" do
      expect { run }.to change(AiGeneration, :count).by(0)

      expect(image.reload).to be_failed
      expect(image.failure_reason).to match(/could not be generated/)
    end
  end

  context "when the game pool has no working key" do
    before do
      stub_moderation(flagged: false)
      stub_funding(raises: Ai::Funding::Exhausted.new("no key"))
    end

    it "fails the skeleton, no audit row" do
      expect { run }.to change(AiGeneration, :count).by(0)
      expect(image.reload).to be_failed
    end
  end
end
