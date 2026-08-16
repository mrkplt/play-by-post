FactoryBot.define do
  factory :page do
    game
    sequence(:title) { |n| "Page #{n}" }
    body { "# Heading\n\nSome **markdown** body." }

    # A page save snapshots a PageVersion attributed to Current.user (a page has
    # no owning user to fall back to — attribution matters for a future
    # edit-control policy). Tests that build pages directly rarely set a current
    # user, so the factory supplies one for the duration of the create and
    # restores it afterward. Pass `editor:` to attribute the version to a
    # specific user.
    transient do
      editor { association(:user) }
    end

    to_create do |page, context|
      previous = Current.user
      Current.user = context.editor
      begin
        page.save!
      ensure
        Current.user = previous
      end
    end
  end
end
