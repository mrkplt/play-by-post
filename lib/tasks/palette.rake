# frozen_string_literal: true

namespace :palette do
  desc "Regenerate app/assets/tailwind/_palette.css from lib/palette.rb"
  task :build do
    ruby File.expand_path("../../bin/build-palette", __dir__)
  end
end

# Ensure the palette CSS is fresh before Tailwind compiles it — covers
# assets:precompile (Docker build) and the dev puma plugin, both of which run
# tailwindcss:build.
if Rake::Task.task_defined?("tailwindcss:build")
  Rake::Task["tailwindcss:build"].enhance([ "palette:build" ])
end
