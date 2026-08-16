# typed: true

# Owns the OpenRouter chat-completions HTTP call for EmailContentExtractor:
# builds the Net::HTTP request, sends it, and parses the JSON body. Split out
# so the http/uri/request setup lives with the object that is actually about
# them, rather than being read piecemeal by the extractor. Namespaced under
# its own top-level module here (the extractor class itself is not reopened
# in this file) so this stateless collaborator isn't misread by tooling as
# the extractor losing its instance state.
module EmailContentExtraction
  module OpenrouterRequest
    extend T::Sig

    # The chat-completion inputs needed to build the request body, grouped so
    # #call and #build_request take one object instead of a four-way
    # parameter list. A Data value object (not a T::Struct subclass) so this
    # stateless-module file has no `class` keyword for check-service-modules
    # to flag.
    Prompt = Data.define(:api_key, :model, :system_prompt, :raw_body)

    sig { params(prompt: EmailContentExtraction::OpenrouterRequest::Prompt).returns(T::Hash[String, T.untyped]) }
    def self.call(prompt)
      uri = URI(EmailContentExtractor::OPENROUTER_API_URL)
      http = build_http(uri)
      request = build_request(uri, prompt)

      JSON.parse(http.request(request).body)
    end

    # T.untyped return so specs can stub with a plain instance_double(Net::HTTP)
    # (sorbet-runtime enforces a concrete Net::HTTP return type against a
    # verifying double's class).
    sig { params(uri: URI::Generic).returns(T.untyped) }
    def self.build_http(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 15
      end
    end

    sig do
      params(
        uri: URI::Generic, prompt: EmailContentExtraction::OpenrouterRequest::Prompt
      ).returns(Net::HTTP::Post)
    end
    def self.build_request(uri, prompt)
      Net::HTTP::Post.new(uri).tap do |request|
        request["Authorization"] = "Bearer #{prompt.api_key}"
        request["Content-Type"] = "application/json"
        request.body = JSON.generate({
          model: prompt.model,
          messages: [
            { role: "system", content: prompt.system_prompt },
            { role: "user", content: prompt.raw_body }
          ]
        })
      end
    end

    private_class_method :build_http, :build_request
  end
end
