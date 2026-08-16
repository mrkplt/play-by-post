# typed: false
# frozen_string_literal: true

require "json-schema"

module Api
  # Rack middleware that validates the JSON request body of /api writes against
  # the OpenAPI document (openapi/v1/openapi.yaml) — the same document generated
  # from the request specs and served as Swagger UI. This is the live half of
  # "one schema, two consumers": a request whose body violates the documented
  # requestBody schema is rejected here with a 400 before it reaches a controller.
  #
  # Deliberately small and owned rather than a general OpenAPI validation gem: the
  # surface is a handful of POST/PATCH operations, so matching path+method to the
  # operation's requestBody schema and running json-schema against the parsed body
  # is a few lines — and the error shape and pass-through rules stay under our
  # control. Only request bodies are validated; auth, per-record authorization and
  # business rules remain the controllers' and policies' job (401/403/422).
  class SchemaValidation
    ERROR_HEADERS = { "Content-Type" => "application/json" }.freeze
    BODY_METHODS = %w[POST PUT PATCH].freeze

    def initialize(app, document_path:)
      @app = app
      @document = load_document(document_path)
    end

    def call(env)
      errors = errors_for(Rack::Request.new(env))
      errors.empty? ? @app.call(env) : error_response(errors)
    end

    private

    # The schema errors for a request, or [] when there is nothing to validate
    # (no document, no body operation) or the body conforms.
    def errors_for(request)
      schema = body_schema_for(request)
      schema ? validate_body(request, schema) : []
    end

    # The OpenAPI document, or nil when it is absent (the asset-precompile build
    # runs with SECRET_KEY_BASE_DUMMY and no generated doc — validate nothing
    # rather than raise). A committed doc is present in every real request env.
    def load_document(document_path)
      return nil if ENV["SECRET_KEY_BASE_DUMMY"]
      return nil unless File.exist?(document_path)

      YAML.safe_load_file(document_path)
    end

    # The requestBody JSON schema (with component refs inlined) for this request's
    # operation, or nil when the request has no body to validate, the document is
    # absent, or the path/method isn't a documented body operation.
    def body_schema_for(request)
      return nil unless @document && BODY_METHODS.include?(request.request_method)

      ref = operation_for(request)&.dig("requestBody", "content", "application/json", "schema")
      ref && { "components" => @document["components"] }.merge(resolve(ref))
    end

    # Matches the concrete request path to an OpenAPI path template (…/{slug}) and
    # returns that path item's operation for the request method.
    def operation_for(request)
      method = request.request_method.downcase
      segments = request.path.split("/")

      @document.fetch("paths", {}).each do |template, item|
        return item[method] if item.key?(method) && path_matches?(template, segments)
      end
      nil
    end

    def path_matches?(template, segments)
      parts = template.split("/")
      return false unless parts.length == segments.length

      parts.zip(segments).all? { |part, seg| part.start_with?("{") || part == seg }
    end

    # Inlines a top-level `$ref` into components so json-schema can resolve it; a
    # non-ref schema is returned unchanged.
    def resolve(schema)
      ref = schema["$ref"]
      return schema unless ref

      { "$ref" => ref }
    end

    def validate_body(request, schema)
      JSON::Validator.fully_validate(schema, JSON.parse(read_body(request).presence || "null"))
    rescue JSON::ParserError
      [ "Request body must be valid JSON." ]
    end

    def read_body(request)
      body = request.body
      body.read.tap { body.rewind }
    end

    def error_response(errors)
      [ 400, ERROR_HEADERS.dup, [ JSON.generate(errors: errors) ] ]
    end
  end
end
