Rails.application.config.after_initialize do
  if Rails.env.local?
    ActionDispatch::DebugView::RESCUES_TEMPLATE_PATHS.unshift(
      Rails.root.join("app/views/debug").to_s
    )
  end
end
