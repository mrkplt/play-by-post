FactoryBot.define do
  factory :scene_summary do
    scene
    sequence(:body) { |n| "Summary body #{n}" }
    generated_at { nil }
    edited_at { nil }
    edited_by { nil }

    # A summary save snapshots a SceneSummaryVersion attributed to Current.user
    # (falling back to the summary's own edited_by). Tests that build summaries
    # directly rarely set a current user, so the factory supplies one for the
    # duration of the create and restores it afterward. Pass `editor:` to
    # attribute the version to a specific user.
    transient do
      editor { association(:user) }
    end

    to_create do |summary, context|
      previous = Current.user
      Current.user = context.editor
      begin
        summary.save!
      ensure
        Current.user = previous
      end
    end

    trait :ai_generated do
      generated_at { Time.current }
    end

    trait :edited do
      edited_at { Time.current }
      association :edited_by, factory: :user
    end
  end
end
