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

    extracted_content(make_request(api_key))
  rescue StandardError
    @raw_body
  end

  private

  # Returns the extracted content, recording AI usage as a side effect, or
  # falls back to the raw body when the response carries no content.
  sig { params(response: T::Hash[String, T.untyped]).returns(String) }
  def extracted_content(response)
    content = response.dig("choices", 0, "message", "content").presence
    return @raw_body unless content

    record_usage(response)
    content
  end

  sig { params(api_key: String).returns(T::Hash[String, T.untyped]) }
  def make_request(api_key)
    prompt = EmailContentExtraction::OpenrouterRequest::Prompt.new(
      api_key: api_key, model: MODEL, system_prompt: SYSTEM_PROMPT, raw_body: @raw_body
    )
    EmailContentExtraction::OpenrouterRequest.call(prompt)
  end

  sig { params(response: T::Hash[String, T.untyped]).void }
  def record_usage(response)
    usage = response["usage"] || {}
    AiUsage.create!(
      feature:       "inbound_email",
      model_used:    response.fetch("model", MODEL),
      input_tokens:  usage["prompt_tokens"],
      output_tokens: usage["completion_tokens"]
    )
  rescue StandardError => error
    Rails.logger.error("AiUsage write failed: #{error.message}")
  end
end
