require "rails_helper"

RSpec.describe ScenePresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }

  subject(:presenter) { described_class.new(scene) }

  describe "#can_post?" do
    let(:user) { build_stubbed(:user) }
    let(:new_post) { instance_double(Post) }

    before { allow(scene).to receive(:posts).and_return(double(new: new_post)) }

    def stub_policy(create:)
      allow(PostPolicy).to receive(:new).with(user, new_post)
        .and_return(instance_double(PostPolicy, create?: create))
    end

    it "is true when the post policy allows it and the scene is open" do
      stub_policy(create: true)
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.can_post?(user)).to be(true)
    end

    it "is false when the scene is resolved" do
      stub_policy(create: true)
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.can_post?(user)).to be(false)
    end

    it "is false when the post policy denies it" do
      stub_policy(create: false)
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.can_post?(user)).to be(false)
    end
  end

  describe "#parent_option_label" do
    context "when active" do
      it { expect(presenter.parent_option_label).to eq(scene.title) }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.parent_option_label).to eq("#{scene.title} (Resolved)") }
    end
  end

  describe "#status_label" do
    context "when active" do
      it { expect(presenter.status_label).to eq("Active") }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.status_label).to eq("Resolved") }
    end
  end

  describe "#formatted_created_at" do
    it "formats the timestamp" do
      expect(presenter.formatted_created_at).to eq("Mar 10, 2024  9:00am")
    end
  end

  describe "#participant_names" do
    it "returns empty string when there are no participants" do
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [])
      )
      expect(presenter.participant_names).to eq("")
    end

    it "includes participants without characters (e.g. GM)" do
      sp = double(display_name: "Alice")
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [ sp ])
      )
      expect(presenter.participant_names).to eq("Alice")
    end

    it "joins multiple participants with a comma" do
      sp1 = double(display_name: "Alice")
      sp2 = double(display_name: "Bob")
      allow(scene).to receive(:scene_participants).and_return(
        double(includes: [ sp1, sp2 ])
      )
      expect(presenter.participant_names).to eq("Alice, Bob")
    end
  end

  describe "#tree_row_css_class" do
    context "when active" do
      it { expect(presenter.tree_row_css_class).to eq("font-semibold") }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.tree_row_css_class).to eq("text-slate-500") }
    end
  end

  describe "#tree_link_css_class" do
    context "when active" do
      it { expect(presenter.tree_link_css_class).to eq("") }
    end

    context "when resolved" do
      let(:scene) { build(:scene, :resolved) }

      it { expect(presenter.tree_link_css_class).to eq("text-slate-500") }
    end
  end

  describe "#banner_image" do
    it "returns a variant with correct transformations" do
      scene = build(:scene)
      scene.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                         filename: "banner.png", content_type: "image/png")
      result = described_class.new(scene).banner_image
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_limit: [ 1200, nil ], format: :jpeg, quality: 85
      )
    end
  end

  describe "#participant_summary" do
    # Only the count reaches the pluralisation, so stub the association the way
    # #participant_names above already does rather than inserting participants.
    def summary_for(count)
      allow(scene).to receive(:scene_participants).and_return(double(count: count))
      presenter.participant_summary
    end

    it "pluralizes for zero participants" do
      expect(summary_for(0)).to eq("0 participants")
    end

    it "singularizes for one participant" do
      expect(summary_for(1)).to eq("1 participant")
    end

    it "pluralizes for several participants" do
      expect(summary_for(2)).to eq("2 participants")
    end
  end

  describe "delegation" do
    it "delegates resolved? to the model" do
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.resolved?).to be true
    end

    it "delegates private? to the model" do
      allow(scene).to receive(:private?).and_return(true)
      expect(presenter.private?).to be true
    end

    it "delegates title to the model" do
      expect(presenter.title).to eq(scene.title)
    end
  end
end
