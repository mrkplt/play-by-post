source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Tailwind CSS for styling [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Icon library [https://github.com/Rails-Designer/icons]
gem "icons"
gem "resend", "~> 1.6"
gem "aws-sdk-s3", "~> 1.228", require: false, group: :production

# Error tracking — reports to GlitchTip (self-hosted, Sentry-protocol compatible)
gem "sentry-ruby"
gem "sentry-rails"

# SQLite everywhere, including production. In production the database files live
# on a mounted volume shared by the web and worker containers — see
# docker-compose.coolify.yml and docs/CONFIGURATION.md.
gem "sqlite3", "~> 2.9"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 8.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache and Active Job
gem "solid_cache"
gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Auth
gem "devise"
gem "devise-passwordless"
# Server-side session store — sessions rows live in the primary SQLite DB on the
# mounted volume, so a login survives deploys/restarts (see docs/CONFIGURATION.md).
gem "activerecord-session_store"

# Authorization — per-model policy objects
gem "pundit"

# Edge rate-limiting / abuse throttling (infrastructure-tier hard stop)
gem "rack-attack"

# Markdown rendering
gem "redcarpet"

# Pagination
gem "pagy", "~> 43.4"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.0"
# image_processing 2.0 dropped its automatic mini_magick dependency; Active
# Storage's ImageMagick transformer still requires the gem, so declare it.
gem "mini_magick", "~> 5.0"

gem "view_component"
gem "draper"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop", "~> 1.88", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-erb", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "mutant-rspec", require: false
  gem "reek", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener_web"
  gem "sorbet", require: false
  gem "tapioca", require: false
end

group :test do
  gem "capybara"
  gem "capybara-playwright-driver"
  gem "simplecov", require: false
  gem "timecop"
  gem "activerecord-nulldb-adapter", require: false
end

gem "sorbet-runtime"

# Zip archive creation for game exports
gem "rubyzip", "~> 3.2"

# OpenAI-compatible client for OpenRouter AI integration
gem "ruby-openai", "~> 8.1"
