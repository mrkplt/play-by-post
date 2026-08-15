require "rails_helper"

RSpec.describe Ui::FormErrorsComponent, type: :component do
  def rendered(messages)
    render_inline(described_class.new(messages: messages))
    page
  end

  it "renders nothing when there are no messages" do
    expect(rendered([]).native.text).to be_empty
  end

  it "does not render the container when there are no messages" do
    expect(rendered([])).to have_no_css("div")
  end

  it "renders a single message" do
    expect(rendered([ "Title can't be blank" ]))
      .to have_css("div", text: "Title can't be blank")
  end

  it "renders every message on its own line" do
    expect(rendered([ "Title can't be blank", "Body can't be blank" ]))
      .to have_css("div.#{described_class::CLASSES.split.first} > div", count: 2)
  end

  it "renders each message's text" do
    page = rendered([ "Title can't be blank", "Body can't be blank" ])
    expect(page).to have_css("div", text: "Title can't be blank")
    expect(page).to have_css("div", text: "Body can't be blank")
  end

  it "carries the error tint classes" do
    expect(rendered([ "boom" ]).find("div", match: :first)[:class])
      .to eq(described_class::CLASSES)
  end

  it "exposes the messages it was given" do
    expect(described_class.new(messages: [ "a" ]).messages).to eq([ "a" ])
  end

  it "renders when there is at least one message" do
    expect(described_class.new(messages: [ "a" ]).render?).to be(true)
  end

  it "does not render when the message list is empty" do
    expect(described_class.new(messages: []).render?).to be(false)
  end

  it "escapes message content" do
    expect(rendered([ "<script>alert(1)</script>" ]).native.to_html)
      .to include("&lt;script&gt;")
  end
end
