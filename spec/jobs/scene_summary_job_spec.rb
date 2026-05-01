require "rails_helper"

RSpec.describe SceneSummaryJob, type: :job do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, :resolved, game: game) }

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
    end

    it "creates a SceneSummary for the scene" do
      expect { described_class.new.perform(scene.id) }.to change(SceneSummary, :count).by(1)
      summary = SceneSummary.find_by!(scene: scene)
      expect(summary.body).to eq("A heroic tale.")
      expect(summary.model_used).to eq("openai/gpt-4o")
      expect(summary.generated_at).to be_present
      expect(summary.input_tokens).to eq(100)
      expect(summary.output_tokens).to eq(40)
      expect(summary.edited_at).to be_nil
      expect(summary.edited_by_id).to be_nil
    end

    it "upserts on re-run (does not create duplicate)" do
      described_class.new.perform(scene.id)
      new_result = SceneSummaryService::Result.new(
        body: "Updated tale.",
        model_used: "openai/gpt-4o",
        input_tokens: 200,
        output_tokens: 60
      )
      service_double = instance_double(SceneSummaryService, call: new_result)
      allow(SceneSummaryService).to receive(:new).with(scene).and_return(service_double)

      expect { described_class.new.perform(scene.id) }.not_to change(SceneSummary, :count)
      expect(SceneSummary.find_by!(scene: scene).body).to eq("Updated tale.")
    end

    it "resets edited_at and edited_by_id to nil when upserting over an existing edited summary" do
      user = create(:user, :with_profile)
      create(:game_member, game: game, user: user)
      scene.create_scene_summary!(body: "Old text.", edited_at: Time.current, edited_by: user)

      described_class.new.perform(scene.id)

      summary = SceneSummary.find_by!(scene: scene)
      expect(summary.body).to eq("A heroic tale.")
      expect(summary.edited_at).to be_nil
      expect(summary.edited_by_id).to be_nil
    end

    it "does nothing if scene does not exist" do
      expect(SceneSummaryService).not_to receive(:new)
      expect { described_class.new.perform(0) }.not_to change(SceneSummary, :count)
    end

    it "logs and swallows ConfigurationError" do
      allow(SceneSummaryService).to receive(:new).and_raise(SceneSummaryService::ConfigurationError, "no key")
      expect(Rails.logger).to receive(:error).with(/no key/)
      expect { described_class.new.perform(scene.id) }.not_to raise_error
    end
  end
end
