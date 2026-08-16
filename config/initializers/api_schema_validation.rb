# typed: false

# Mount Api::SchemaValidation so every /api request body is validated against the
# generated OpenAPI document before it reaches a controller. The middleware
# itself no-ops when the document is absent (the SECRET_KEY_BASE_DUMMY asset
# build) or when a request has no body/operation to validate, so it is always
# safe to insert.
require "api/schema_validation"

Rails.application.config.middleware.use(
  Api::SchemaValidation,
  document_path: Rails.root.join("openapi/v1/openapi.yaml").to_s
)
