require "rails_helper"

RSpec.describe InboundMailBuilder do
  def build(data)
    Mail.read_from_string(described_class.call(data))
  end

  it "sets from, joined to, and subject headers" do
    mail = build("from" => "gm@example.com", "to" => [ "a@example.com", "b@example.com" ], "subject" => "Re: scene", "text" => "hi")
    expect(mail.from).to eq([ "gm@example.com" ])
    expect(mail.to).to eq([ "a@example.com", "b@example.com" ])
    expect(mail.subject).to eq("Re: scene")
  end

  it "builds a text-only body when only text is present" do
    mail = build("from" => "g@x", "to" => "p@x", "subject" => "s", "text" => "just text")
    expect(mail).not_to be_multipart
    expect(mail.body.decoded).to eq("just text")
  end

  it "builds an html-only body when only html is present" do
    mail = build("from" => "g@x", "to" => "p@x", "subject" => "s", "html" => "<p>hi</p>")
    expect(mail).not_to be_multipart
    expect(mail.content_type).to start_with("text/html")
    expect(mail.body.decoded).to eq("<p>hi</p>")
  end

  it "builds a multipart body with both parts when html and text are present" do
    mail = build("from" => "g@x", "to" => "p@x", "subject" => "s", "html" => "<p>hi</p>", "text" => "hi")
    expect(mail).to be_multipart
    expect(mail.text_part.body.decoded).to eq("hi")
    expect(mail.html_part.body.decoded).to eq("<p>hi</p>")
    expect(mail.html_part.content_type).to start_with("text/html")
  end
end
