require "rails_helper"

# CharacterPortraitJob resolves the pending skeleton and hands off to
# CharacterPortraitGeneration. The pipeline itself is specced in
# character_portrait_generation_spec.
RSpec.describe CharacterPortraitJob, type: :job do
  let(:character) { create(:character) }
  let(:image) { character.character_images.create! }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  it "runs the generation for a pending skeleton" do
    generation = instance_double(CharacterPortraitGeneration, run: nil)
    expect(CharacterPortraitGeneration).to receive(:new).with(image, 42, "a knight").and_return(generation)

    described_class.new.perform(image.id, 42, "a knight")
  end

  it "does nothing when the skeleton no longer exists" do
    expect(CharacterPortraitGeneration).not_to receive(:new)

    expect { described_class.new.perform(-1, 42, "a knight") }.not_to raise_error
  end

  it "does nothing when the image is no longer pending (already completed or failed)" do
    image.fail_generation!("already failed")

    expect(CharacterPortraitGeneration).not_to receive(:new)

    described_class.new.perform(image.id, 42, "a knight")
  end
end
