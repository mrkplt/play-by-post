# typed: false

Rswag::Api.configure do |c|
  # Specify a root folder where Swagger JSON files are located
  # This is used by the Swagger middleware to serve requests for API descriptions
  # NOTE: If you're using rswag-specs to generate Swagger, you'll need to ensure
  # that it's configured to generate files in the same folder
  c.openapi_root = Rails.root.join("openapi").to_s

  # The committed openapi/v1/openapi.yaml carries the open-source defaults ("Play
  # by Post" / play-by-post.example.com) so the checked-in contract is brand-
  # neutral and the freshness gate stays deterministic. This filter rewrites the
  # title and server per-request from the deployment's env, so a running instance
  # (flailwhale.com) serves its own brand without regenerating the file. ENV is
  # read directly because this initializer runs before the app-model autoloader;
  # the defaults mirror Branding::DEFAULT_NAME / DEFAULT_HOST.
  c.swagger_filter = lambda do |swagger, _env|
    name = ENV.fetch("APP_NAME", "Play by Post")
    host = ENV.fetch("APP_HOST", "play-by-post.example.com")
    swagger["info"]["title"] = "#{name} API" if swagger["info"]
    swagger["servers"] = [ { "url" => "https://#{host}" } ]
    swagger
  end
end
