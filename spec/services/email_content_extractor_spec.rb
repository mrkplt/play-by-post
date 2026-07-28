require "rails_helper"

RSpec.describe EmailContentExtractor do
  let(:raw_body) { "Hello, this is my reply.\n\nOn Mon, Jan 1, 2024, someone wrote:\n> Original message" }

  describe "#extract" do
    context "when no API key is configured" do
      before do
        allow(Rails.application.credentials).to receive(:openrouter_api_key).and_return(nil)
      end

      it "returns the raw body without making an HTTP request" do
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "does not create an AiUsage record" do
        expect { described_class.new(raw_body).extract }.not_to change(AiUsage, :count)
      end
    end

    context "when API key is blank" do
      before do
        allow(Rails.application.credentials).to receive(:openrouter_api_key).and_return("")
      end

      it "returns the raw body without making an HTTP request" do
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "does not create an AiUsage record" do
        expect { described_class.new(raw_body).extract }.not_to change(AiUsage, :count)
      end
    end

    context "when API key is present" do
      let(:api_key) { "test-api-key" }
      let(:http_double) { instance_double(Net::HTTP) }
      let(:response_double) { instance_double(Net::HTTPResponse) }

      before do
        allow(Rails.application.credentials).to receive(:openrouter_api_key).and_return(api_key)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_return(response_double)
      end

      it "returns extracted content from the API response" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "Hello, this is my reply." } } ] }.to_json
        )

        expect(described_class.new(raw_body).extract).to eq("Hello, this is my reply.")
      end

      it "connects to the correct host and port" do
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        uri = URI(EmailContentExtractor::OPENROUTER_API_URL)
        expect(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http_double)

        described_class.new(raw_body).extract
      end

      it "sends the correct authorization header" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        described_class.new(raw_body).extract

        expect(http_double).to have_received(:request) do |req|
          expect(req["Authorization"]).to eq("Bearer test-api-key")
        end
      end

      it "sends the correct content type header" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        described_class.new(raw_body).extract

        expect(http_double).to have_received(:request) do |req|
          expect(req["Content-Type"]).to eq("application/json")
        end
      end

      it "sends the system prompt and raw body as messages" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        described_class.new(raw_body).extract

        expect(http_double).to have_received(:request) do |req|
          body = JSON.parse(req.body)
          expect(body["model"]).to eq(EmailContentExtractor::MODEL)
          expect(body["messages"]).to eq([
            { "role" => "system", "content" => EmailContentExtractor::SYSTEM_PROMPT },
            { "role" => "user", "content" => raw_body }
          ])
        end
      end

      it "falls back to raw body when API response has no content" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => nil } } ] }.to_json
        )

        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "falls back to raw body when API response has empty content" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "" } } ] }.to_json
        )

        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "falls back to raw body when API response has no choices" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [] }.to_json
        )

        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "falls back to raw body on network error" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:request).and_raise(SocketError.new("Connection refused"))

        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "falls back to raw body on timeout" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:request).and_raise(Net::ReadTimeout)

        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "falls back to raw body on JSON parse error" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return("not json")

        expect(described_class.new(raw_body).extract).to eq(raw_body)
      end

      it "uses SSL for the request" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        described_class.new(raw_body).extract

        expect(http_double).to have_received(:use_ssl=).with(true)
      end

      it "sets open_timeout to 10 seconds" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        described_class.new(raw_body).extract

        expect(http_double).to have_received(:open_timeout=).with(10)
      end

      it "sets read_timeout to 15 seconds" do
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(response_double).to receive(:body).and_return(
          { "choices" => [ { "message" => { "content" => "reply" } } ] }.to_json
        )

        described_class.new(raw_body).extract

        expect(http_double).to have_received(:read_timeout=).with(15)
      end

      context "when the API call succeeds" do
        let(:api_response) do
          {
            "model"   => "google/gemma-3-4b-it:free",
            "choices" => [ { "message" => { "content" => "Clean reply." } } ],
            "usage"   => { "prompt_tokens" => 150, "completion_tokens" => 30 }
          }.to_json
        end

        before do
          allow(Net::HTTP).to receive(:new).and_return(http_double)
          allow(response_double).to receive(:body).and_return(api_response)
        end

        it "creates an AiUsage record" do
          expect { described_class.new(raw_body).extract }.to change(AiUsage, :count).by(1)
        end

        it "records the correct feature" do
          described_class.new(raw_body).extract
          expect(AiUsage.last.feature).to eq("inbound_email")
        end

        it "records the model returned by the API" do
          described_class.new(raw_body).extract
          expect(AiUsage.last.model_used).to eq("google/gemma-3-4b-it:free")
        end

        it "records input token count" do
          described_class.new(raw_body).extract
          expect(AiUsage.last.input_tokens).to eq(150)
        end

        it "records output token count" do
          described_class.new(raw_body).extract
          expect(AiUsage.last.output_tokens).to eq(30)
        end

        it "falls back to the MODEL constant when response omits model" do
          allow(response_double).to receive(:body).and_return(
            {
              "choices" => [ { "message" => { "content" => "reply" } } ],
              "usage"   => { "prompt_tokens" => 10, "completion_tokens" => 5 }
            }.to_json
          )
          described_class.new(raw_body).extract
          expect(AiUsage.last.model_used).to eq(EmailContentExtractor::MODEL)
        end

        it "still returns the extracted content even when AiUsage.create! raises" do
          allow(AiUsage).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
          expect(described_class.new(raw_body).extract).to eq("Clean reply.")
        end

        it "does not raise when AiUsage.create! fails" do
          allow(AiUsage).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
          expect { described_class.new(raw_body).extract }.not_to raise_error
        end
      end

      context "when the API response has no content (fallback)" do
        before do
          allow(Net::HTTP).to receive(:new).and_return(http_double)
          allow(response_double).to receive(:body).and_return(
            { "choices" => [ { "message" => { "content" => nil } } ] }.to_json
          )
        end

        it "does not create an AiUsage record" do
          expect { described_class.new(raw_body).extract }.not_to change(AiUsage, :count)
        end
      end

      context "when a network error occurs (fallback)" do
        before do
          allow(Net::HTTP).to receive(:new).and_return(http_double)
          allow(http_double).to receive(:request).and_raise(SocketError.new("Connection refused"))
        end

        it "does not create an AiUsage record" do
          expect { described_class.new(raw_body).extract }.not_to change(AiUsage, :count)
        end
      end
    end
  end
end
