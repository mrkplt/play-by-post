FactoryBot.define do
  factory :notebook_entry do
    game
    sequence(:title) { |n| "Notebook Entry #{n}" }
    body { "# Idea\n\nSome **markdown** body." }
    status { "new" }

    # A notebook entry save snapshots a NotebookEntryVersion attributed to
    # Current.user (an entry has no owning user to fall back to — attribution
    # matters). Tests that build entries directly rarely set a current user, so
    # the factory supplies one for the duration of the create and restores it
    # afterward. Pass `editor:` to attribute the version to a specific user.
    transient do
      editor { association(:user) }
    end

    to_create do |entry, context|
      previous = Current.user
      Current.user = context.editor
      begin
        entry.save!
      ensure
        Current.user = previous
      end
    end
  end
end
