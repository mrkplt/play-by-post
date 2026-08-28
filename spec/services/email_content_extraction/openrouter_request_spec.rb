require "rails_helper"

RSpec.describe EmailContentExtraction::OpenrouterRequest do
  let(:prompt) do
    described_class::Prompt.new(
      api_key: "sk-test", model: "openai/gpt-x", system_prompt: "extract", raw_body: "the email body"
    )
  end

  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse, body: '{"choices":[{"message":{"content":"ok"}}]}') }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).and_return(response)
  end

  it "parses the JSON response body" do
    expect(described_class.call(prompt)).to eq("choices" => [ { "message" => { "content" => "ok" } } ])
  end

  it "posts to the OpenRouter completions URL over SSL" do
    uri = URI(EmailContentExtractor::OPENROUTER_API_URL)
    expect(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http)
    expect(http).to receive(:use_ssl=).with(true)
    described_class.call(prompt)
  end

  it "sends the api key, content type, and the model + system/user messages" do
    sent = nil
    allow(http).to receive(:request) { |req| sent = req; response }

    described_class.call(prompt)

    expect(sent["Authorization"]).to eq("Bearer sk-test")
    expect(sent["Content-Type"]).to eq("application/json")
    body = JSON.parse(sent.body)
    expect(body["model"]).to eq("openai/gpt-x")
    expect(body["messages"]).to eq([
      { "role" => "system", "content" => "extract" },
      { "role" => "user", "content" => "the email body" }
    ])
  end
end
