# frozen_string_literal: true

require "rails_helper"

# The OpenAPI document for the machine-auth /api surface is generated from the
# request specs under spec/requests/api by `rake rswag:specs:swaggerize`, written
# to openapi/v1/openapi.yaml. That one document is the single source of truth: it
# is served as Swagger UI at /api-docs, read by API clients, and validated against
# live requests by Api::SchemaValidation (config/initializers/api_schema_validation.rb).
RSpec.configure do |config|
  config.openapi_root = Rails.root.join("openapi").to_s

  config.openapi_specs = {
    "v1/openapi.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "#{Branding.display_name} API",
        version: "v1",
        description: <<~DESC
          Token-authenticated data API for a game's pages and notebook entries.

          Authorization is via bearer token. You can create one in your profile.
        DESC
      },
      paths: {},
      servers: [
        { url: Branding.url }
      ],
      components: {
        securitySchemes: {
          bearer_token: { type: :http, scheme: :bearer }
        },
        schemas: {
          page: {
            type: :object,
            properties: {
              slug: { type: :string, description: "16-char stable identifier" },
              title: { type: :string },
              body: { type: :string, description: "Raw markdown" },
              created_by_id: {
                type: :integer, nullable: true,
                description: "User id of the creator (immutable across versions)"
              },
              edited_by_id: {
                type: :integer, nullable: true,
                description: "User id of the most recent editor"
              },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: %w[slug title body]
          },
          page_input: {
            type: :object,
            properties: {
              page: {
                type: :object,
                properties: {
                  title: { type: :string },
                  body: { type: :string, description: "Raw markdown" }
                }
              }
            },
            required: %w[page]
          },
          notebook_entry: {
            type: :object,
            properties: {
              slug: { type: :string, description: "16-char stable identifier" },
              title: { type: :string },
              body: { type: :string, description: "Raw markdown" },
              status: { type: :string, enum: %w[new expand done discard] },
              created_by_id: {
                type: :integer, nullable: true,
                description: "User id of the creator (immutable across versions)"
              },
              edited_by_id: {
                type: :integer, nullable: true,
                description: "User id of the most recent editor"
              },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: %w[slug title body status]
          },
          notebook_entry_input: {
            type: :object,
            properties: {
              notebook_entry: {
                type: :object,
                properties: {
                  title: { type: :string },
                  body: { type: :string, description: "Raw markdown" },
                  status: {
                    type: :string, enum: %w[new expand done discard],
                    description: "Kanban lane. Optional: omit to keep `new` on create or leave unchanged on update. A status change is validated through the shared lane-move path."
                  }
                }
              }
            },
            required: %w[notebook_entry]
          },
          errors: {
            type: :object,
            properties: {
              errors: { type: :array, items: { type: :string } }
            },
            required: %w[errors]
          }
        }
      },
      security: [ { bearer_token: [] } ]
    }
  }

  config.openapi_format = :yaml
end
