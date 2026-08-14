require "rails_helper"

RSpec.describe FlashPresenter do
  def toasts_for(flash)
    described_class.new(flash).toasts
  end

  it "maps a notice to a success toast" do
    expect(toasts_for("notice" => "Saved.")).to eq([ { message: "Saved.", variant: :success } ])
  end

  it "maps an alert to an error toast" do
    expect(toasts_for("alert" => "Broke.")).to eq([ { message: "Broke.", variant: :error } ])
  end

  it "is empty when the flash is empty" do
    expect(toasts_for({})).to eq([])
  end

  it "drops a blank message rather than rendering an empty toast" do
    expect(toasts_for("notice" => "")).to eq([])
  end

  it "drops a nil message" do
    expect(toasts_for("notice" => nil)).to eq([])
  end

  it "ignores flash keys the app has no visual language for" do
    expect(toasts_for("timedout" => "true")).to eq([])
  end

  # Order is load-bearing: the error is the message that still needs reading
  # after the success toast has faded, so it renders first.
  it "puts the error before the success when both are set" do
    expect(toasts_for("notice" => "Saved.", "alert" => "Broke.")).to eq([
      { message: "Broke.", variant: :error },
      { message: "Saved.", variant: :success }
    ])
  end

  it "orders by variant, not by the order the keys were set" do
    expect(toasts_for("alert" => "Broke.", "notice" => "Saved.").map { |t| t[:variant] })
      .to eq([ :error, :success ])
  end

  it "coerces a non-string message to a string" do
    result = toasts_for("notice" => 42)

    expect(result.first[:message]).to be_a(String).and eq("42")
  end

  it "reads through a real ActionDispatch flash hash" do
    flash = ActionDispatch::Flash::FlashHash.new
    flash[:notice] = "Entry moved."

    expect(described_class.new(flash).toasts).to eq([ { message: "Entry moved.", variant: :success } ])
  end
end
