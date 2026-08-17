# typed: false

Rswag::Ui.configure do |c|
  # List the Swagger endpoints that you want to be documented through the
  # swagger-ui. The first parameter is the path (absolute or relative to the UI
  # host) to the corresponding endpoint and the second is a title that will be
  # displayed in the document selector.
  # NOTE: If you're using rspec-api to expose Swagger files
  # (under openapi_root) as JSON or YAML endpoints, then the list below should
  # correspond to the relative paths for those endpoints.

  # Read ENV directly rather than via Branding: this initializer runs before the
  # app-model autoloader, so referencing Branding here raises uninitialized
  # constant. Keep the default in sync with Branding::DEFAULT_NAME.
  c.swagger_endpoint "/api-docs/v1/openapi.yaml", "#{ENV.fetch('APP_NAME', 'Play by Post')} API V1"

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
