require "rails_helper"

RSpec.describe FizzySweepService do
  let(:api_url) { "https://fizzy.example.com" }
  let(:access_token) { "fizzy-access-token" }
  let(:account_slug) { "mrkplt" }
  let(:board_id) { "board-123" }
  let(:fizzy_config) { double("fizzy", api_url: api_url, access_token: access_token, account_slug: account_slug, board_id: board_id) }
  let(:feedback) { build(:feedback, body: "Add a links section to games.", url: "https://flailwhale.com/games/1") }

  before do
    allow(Rails.application.credentials).to receive(:fizzy).and_return(fizzy_config)
  end

  # Stubs Net::HTTP.start to capture the issued request and return a canned
  # response, avoiding any real network call.
  def stub_http_response(response)
    captured = {}
    allow(Net::HTTP).to receive(:start) do |hostname, port, opts, &block|
      captured[:hostname] = hostname
      captured[:port] = port
      captured[:use_ssl] = opts[:use_ssl]
      http = double("http")
      allow(http).to receive(:request) do |request|
        captured[:request] = request
        response
      end
      block.call(http)
    end
    captured
  end

  describe ".create_card" do
    it "POSTs the card to the board's cards endpoint with a bearer token" do
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))
      expect(Rails.logger).to receive(:debug).with(/Fizzy card created for feedback ##{feedback.id}:/)

      described_class.create_card(feedback)

      expect(captured[:hostname]).to eq("fizzy.example.com")
      expect(captured[:port]).to eq(443)
      expect(captured[:use_ssl]).to be(true)
      expect(captured[:request].method).to eq("POST")
      expect(captured[:request].path).to eq("/mrkplt/boards/board-123/cards")
      expect(captured[:request]["Authorization"]).to eq("Bearer #{access_token}")
      expect(captured[:request]["Content-Type"]).to eq("application/json")
      expect(captured[:request]["Accept"]).to eq("application/json")
    end

    it "sends the feedback as the card title and body" do
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))
      feedback.id = 42

      described_class.create_card(feedback)

      payload = JSON.parse(captured[:request].body).fetch("card")
      expect(payload.fetch("title")).to eq("Feedback #42")
      expect(payload.fetch("description")).to include(feedback.body)
      expect(payload.fetch("description")).to include("Submitted from: #{feedback.url}")
      expect(payload.fetch("description")).to include("Submitted by: #{feedback.user.email}")
    end

    it "captures the submitter's email on the card" do
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))

      described_class.create_card(feedback)

      payload = JSON.parse(captured[:request].body).fetch("card")
      expect(payload.fetch("description")).to include("Submitted by: #{feedback.user.email}")
    end

    it "omits the submitted-by line when there is no submitter" do
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))
      allow(feedback).to receive(:user).and_return(nil)

      described_class.create_card(feedback)

      payload = JSON.parse(captured[:request].body).fetch("card")
      expect(payload.fetch("description")).not_to include("Submitted by:")
    end

    it "omits the submitted-from line when the entry has no URL" do
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))
      feedback.url = nil

      described_class.create_card(feedback)

      payload = JSON.parse(captured[:request].body).fetch("card")
      expect(payload.fetch("description")).not_to include("Submitted from:")
    end

    it "omits the submitted-from line when the URL is blank" do
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))
      feedback.url = ""

      described_class.create_card(feedback)

      payload = JSON.parse(captured[:request].body).fetch("card")
      expect(payload.fetch("description")).not_to include("Submitted from:")
    end

    it "does not use TLS for an http API URL" do
      allow(fizzy_config).to receive(:api_url).and_return("http://fizzy.internal")
      captured = stub_http_response(Net::HTTPCreated.new("1.1", "201", "Created"))

      described_class.create_card(feedback)

      expect(captured[:use_ssl]).to be(false)
    end

    it "raises when Fizzy returns a non-success response" do
      stub_http_response(Net::HTTPServerError.new("1.1", "500", "Internal Server Error"))

      expect { described_class.create_card(feedback) }
        .to raise_error(/Fizzy card creation failed: 500/)
    end

    context "when configuration is missing" do
      it "raises ConfigurationError referencing api_url" do
        allow(fizzy_config).to receive(:api_url).and_return(nil)

        expect { described_class.create_card(feedback) }
          .to raise_error(FizzySweepService::ConfigurationError, /api_url/)
      end

      it "raises ConfigurationError referencing access_token" do
        allow(fizzy_config).to receive(:access_token).and_return(nil)

        expect { described_class.create_card(feedback) }
          .to raise_error(FizzySweepService::ConfigurationError, /access_token/)
      end

      it "raises ConfigurationError referencing account_slug" do
        allow(fizzy_config).to receive(:account_slug).and_return(nil)

        expect { described_class.create_card(feedback) }
          .to raise_error(FizzySweepService::ConfigurationError, /account_slug/)
      end

      it "raises ConfigurationError referencing board_id" do
        allow(fizzy_config).to receive(:board_id).and_return(nil)

        expect { described_class.create_card(feedback) }
          .to raise_error(FizzySweepService::ConfigurationError, /board_id/)
      end

      it "raises ConfigurationError when the fizzy credential is entirely absent" do
        allow(Rails.application.credentials).to receive(:fizzy).and_return(nil)

        expect { described_class.create_card(feedback) }
          .to raise_error(FizzySweepService::ConfigurationError, /fizzy is not configured/)
      end
    end
  end
end
