# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading, unconditionally — deliberately not the Rails default of
  # `ENV["CI"].present?`, which loads lazily on a developer's machine and eagerly
  # on CI. That split makes the test environment behave differently in the two
  # places it runs, and it has already cost us: under eager loading ViewComponent
  # compiles a templateless component's `call` at boot, so mutant's rewrite of
  # that method is a no-op and every mutation of it survives. A branch measured
  # 98.33% mutation coverage locally and 60% on CI — below the floor — with a
  # green suite both times, and the gap was environment, not code.
  #
  # The saving that split buys is not worth it: measured at ~0.4s on a
  # single-file run and nil on the full tier (1889 examples: 4.73s lazy vs 4.75s
  # eager), because the suite ends up loading nearly everything anyway. Eager
  # loading also catches a class of bug nothing else here does — a file no spec
  # references that fails to load is silently green when lazy-loaded.
  config.eager_load = true

  # Configure public file server for tests with cache-control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Run jobs inline so deliver_later emails are captured synchronously in tests.
  config.active_job.queue_adapter = :inline

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "example.com" }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Action Cable's :test adapter records broadcasts for the turbo-rails
  # assertion helpers (assert_turbo_stream_broadcasts / have_broadcasted_to) and
  # replays them to sockets connected in a system test, so a Playwright feature
  # spec sees a real broadcast swap the pending frame. cable.yml already selects
  # it for the test env; pinned here alongside the queue/mailer test adapters so
  # the test-time messaging setup reads in one place.
  config.action_cable.disable_request_forgery_protection = true
end
