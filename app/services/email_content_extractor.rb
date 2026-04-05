# typed: strict

class EmailContentExtractor
  extend T::Sig

  OPENROUTER_API_URL = T.let("https://openrouter.ai/api/v1/chat/completions", String)
  MODEL = T.let("google/gemma-3-4b-it:free", String)

  SYSTEM_PROMPT = T.let(<<~PROMPT.freeze, String)
    You are an email reply extractor. Extract only the new content the user wrote.
    Remove all quoted/replied text, email signatures, forwarded messages, and metadata.
    Return only the clean message body. No explanation, no commentary — just the extracted text.
  PROMPT

  sig { params(raw_body: String).void }
  def initialize(raw_body)
    @raw_body = raw_body
  end

  sig { returns(String) }
  def extract
    api_key = Rails.application.credentials.openrouter_api_key
    return @raw_body if api_key.blank?

    response = make_request(api_key)
    response.dig("choices", 0, "message", "content").presence || @raw_body
  rescue StandardError
    @raw_body
  end

  private

  sig { params(api_key: String).returns(T::Hash[String, T.untyped]) }
  def make_request(api_key)
    uri = URI(OPENROUTER_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate({
      model: MODEL,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: @raw_body }
      ]
    })

    JSON.parse(http.request(request).body)
  end
end
