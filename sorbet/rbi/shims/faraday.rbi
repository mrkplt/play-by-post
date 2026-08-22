# typed: true

module Faraday
  class Middleware; end

  # Faraday raises Error subclasses for HTTP failures; ruby-openai surfaces
  # them from client.chat. `response_status` carries the HTTP status code we
  # classify key-attributable failures on (see SceneSummaryService).
  class Error < StandardError
    sig { returns(T.nilable(Integer)) }
    def response_status; end
  end
end
