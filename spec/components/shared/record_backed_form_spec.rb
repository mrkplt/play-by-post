require "rails_helper"

RSpec.describe Shared::RecordBackedForm do
  # A minimal includer, so the module is tested for its own behaviour rather
  # than through any one form component's incidental setup. Named rather than
  # an anonymous Class.new — an anonymous class's `initialize` is defined on
  # Object as far as Sorbet is concerned, which breaks unrelated call sites.
  class TestForm
    include Shared::RecordBackedForm

    def initialize(record)
      @record = record
    end

    def record = @record
  end

  let(:includer) { TestForm }

  let(:record) do
    instance_double(
      PagePresenter,
      new_record?: true,
      errors?: true,
      error_messages: [ "Title can't be blank" ]
    )
  end

  subject(:form) { includer.new(record) }

  it "delegates new_record? to the record" do
    expect(form.new_record?).to be(true)
  end

  it "delegates errors? to the record" do
    expect(form.errors?).to be(true)
  end

  it "delegates error_messages to the record" do
    expect(form.error_messages).to eq([ "Title can't be blank" ])
  end

  it "reflects a persisted record" do
    allow(record).to receive(:new_record?).and_return(false)
    expect(form.new_record?).to be(false)
  end

  it "reflects a record without errors" do
    allow(record).to receive(:errors?).and_return(false)
    expect(form.errors?).to be(false)
  end

  it "reflects an empty message list" do
    allow(record).to receive(:error_messages).and_return([])
    expect(form.error_messages).to eq([])
  end
end
