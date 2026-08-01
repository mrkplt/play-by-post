# typed: false
# frozen_string_literal: true

# ViewComponent previews live alongside the component specs (spec/components/
# previews). Register that path so Lookbook (dev-only, mounted at /lookbook) can
# render the design-system gallery.
preview_path = Rails.root.join("spec/components/previews").to_s
config = Rails.application.config.view_component
config.preview_paths = Array(config.preview_paths) | [ preview_path ]
