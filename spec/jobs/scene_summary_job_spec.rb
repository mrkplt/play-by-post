require "rails_helper"

RSpec.describe SceneSummaryJob, type: :job do
  let(:game) { create(:game) }
  let(:requester) { create(:user, :with_profile) }
  let(:payer) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game) }

  let(:generation_result) do
    Ai::UserGeneration::Result.new(
      body: "A heroic tale.",
      model_used: "openai/gpt-4o",
      input_tokens: 100,
      output_tokens: 40,
      cost: 0.0055,
      funded_by: payer
    )
  end

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before do
    generation_double = instance_double(Ai::UserGeneration, call: generation_result)
    allow(Ai::UserGeneration).to receive(:new)
      .with(feature: SceneSummaryJob::FEATURE, game: scene.game)
      .and_return(generation_double)
  end

  describe "#perform" do
    it "upserts only body and generated_at (no accounting columns on the summary)" do
      described_class.new.perform(scene.id, requester.id)

      summary = SceneSummary.find_by(scene_id: scene.id)
      expect(summary.body).to eq("A heroic tale.")
      expect(summary.generated_at).to be_present
    end

    it "clears any previous manual edit when it upserts" do
      create(:scene_summary, :edited, scene: scene)

      described_class.new.perform(scene.id, requester.id)

      summary = SceneSummary.find_by(scene_id: scene.id)
      expect(summary.edited_at).to be_nil
      expect(summary.edited_by_id).to be_nil
    end

    it "stamps generated_at to now" do
      described_class.new.perform(scene.id, requester.id)

      summary = SceneSummary.find_by(scene_id: scene.id)
      expect(summary.generated_at).to be_within(1.second).of(Time.current)
    end

    it "snapshots a version marked AI-authored, attributed to the requester" do
      described_class.new.perform(scene.id, requester.id)

      summary = SceneSummary.find_by(scene_id: scene.id)
      version = summary.scene_summary_versions.last
      expect(version.generated_at).to be_present
      expect(version.body).to eq(summary.body)
      expect(version.edited_by_id).to eq(requester.id)
    end

    it "records a second version when a generation overwrites an existing summary" do
      create(:scene_summary, scene: scene, body: "old", editor: requester)

      expect { described_class.new.perform(scene.id, requester.id) }
        .to change { SceneSummary.find_by(scene_id: scene.id).scene_summary_versions.count }.by(1)
    end

    it "writes exactly one AiGeneration row with feature/model/tokens/cost/requester/payer/asset" do
      expect { described_class.new.perform(scene.id, requester.id) }
        .to change(AiGeneration, :count).by(1)

      audit = AiGeneration.last
      summary = SceneSummary.find_by(scene_id: scene.id)

      expect(audit.feature).to eq("scene_summary")
      expect(audit.model_used).to eq("openai/gpt-4o")
      expect(audit.input_tokens).to eq(100)
      expect(audit.output_tokens).to eq(40)
      expect(audit.cost).to eq(0.0055)
      expect(audit.requested_by_id).to eq(requester.id)
      expect(audit.funded_by_id).to eq(payer.id)
      expect(audit.asset_type).to eq("SceneSummary")
      expect(audit.asset_id).to eq(summary.id)
    end

    it "records requester and payer correctly when they are different users" do
      described_class.new.perform(scene.id, requester.id)

      audit = AiGeneration.last
      expect(audit.requested_by_id).to eq(requester.id)
      expect(audit.funded_by_id).to eq(payer.id)
      expect(audit.requested_by_id).not_to eq(audit.funded_by_id)
    end

    it "records requester and payer correctly when the resolver funded their own generation" do
      self_funded_result = Ai::UserGeneration::Result.new(
        body: "Self-funded tale.", model_used: "openai/gpt-4o",
        input_tokens: 10, output_tokens: 5, cost: 0.001, funded_by: requester
      )
      allow(Ai::UserGeneration).to receive(:new)
        .with(feature: SceneSummaryJob::FEATURE, game: scene.game)
        .and_return(instance_double(Ai::UserGeneration, call: self_funded_result))

      described_class.new.perform(scene.id, requester.id)

      audit = AiGeneration.last
      expect(audit.requested_by_id).to eq(requester.id)
      expect(audit.funded_by_id).to eq(requester.id)
    end

    it "does nothing if scene does not exist" do
      expect { described_class.new.perform(0, requester.id) }
        .not_to change(AiGeneration, :count)

      expect(SceneSummary.find_by(scene_id: 0)).to be_nil
    end

    it "rolls back the summary upsert if the audit row fails to save" do
      allow(AiGeneration).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(AiGeneration.new))

      expect { described_class.new.perform(scene.id, requester.id) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(SceneSummary.find_by(scene_id: scene.id)).to be_nil
    end

    it "logs and swallows Ai::Funding::Exhausted, writing no summary and no audit row" do
      allow(Ai::UserGeneration).to receive(:new)
        .with(feature: SceneSummaryJob::FEATURE, game: scene.game)
        .and_return(instance_double(Ai::UserGeneration).tap { |d|
          allow(d).to receive(:call).and_raise(Ai::Funding::Exhausted, "no working BYOK key")
        })
      expect(Rails.logger).to receive(:error).with(/no working BYOK key/)

      expect { described_class.new.perform(scene.id, requester.id) }.not_to raise_error

      expect(SceneSummary.find_by(scene_id: scene.id)).to be_nil
      expect(AiGeneration.count).to eq(0)
    end
  end

  describe "#perform broadcasting the finished summary" do
    it "broadcasts the summary to every visibility class after upserting it" do
      expect(SceneSummaryBroadcast).to receive(:new)
        .with(an_instance_of(SceneSummary)).and_call_original

      described_class.new.perform(scene.id, requester.id)

      expect(SceneSummary.find_by(scene_id: scene.id)&.body).to eq("A heroic tale.")
    end
  end
end
