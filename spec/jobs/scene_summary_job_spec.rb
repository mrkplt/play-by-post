require "rails_helper"

RSpec.describe SceneSummaryJob, type: :job do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, :resolved, game: game) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  describe "#perform" do
    let(:service_result) do
      SceneSummaryService::Result.new(
        body: "A heroic tale.",
        model_used: "openai/gpt-4o",
        input_tokens: 100,
        output_tokens: 40
      )
    end

    before do
      service_double = instance_double(SceneSummaryService, call: service_result)
      allow(SceneSummaryService).to receive(:new).with(scene).and_return(service_double)
      allow(Scene).to receive(:find_by).with(id: scene.id).and_return(scene)
      allow(SceneSummary).to receive(:upsert)
    end

    it "upserts the summary the service produced, keyed on the scene" do
      described_class.new.perform(scene.id)

      expect(SceneSummary).to have_received(:upsert).with(
        hash_including(
          scene_id: scene.id,
          body: "A heroic tale.",
          model_used: "openai/gpt-4o",
          input_tokens: 100,
          output_tokens: 40
        ),
        hash_including(unique_by: :scene_id)
      )
    end

    it "clears any previous manual edit when it upserts" do
      described_class.new.perform(scene.id)

      expect(SceneSummary).to have_received(:upsert)
        .with(hash_including(edited_at: nil, edited_by_id: nil), anything)
    end

    it "stamps generated_at" do
      Timecop.freeze do
        described_class.new.perform(scene.id)

        expect(SceneSummary).to have_received(:upsert)
          .with(hash_including(generated_at: Time.current), anything)
      end
    end

    it "does nothing if scene does not exist" do
      allow(Scene).to receive(:find_by).with(id: 0).and_return(nil)

      described_class.new.perform(0)

      expect(SceneSummary).not_to have_received(:upsert)
    end

    it "logs and swallows ConfigurationError" do
      allow(SceneSummaryService).to receive(:new).and_raise(SceneSummaryService::ConfigurationError, "no key")
      expect(Rails.logger).to receive(:error).with(/no key/)

      expect { described_class.new.perform(scene.id) }.not_to raise_error
    end
  end
end
