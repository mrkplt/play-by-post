FactoryBot.define do
  factory :ai_generation do
    feature         { "scene_summary" }
    model_used      { "openai/gpt-4o" }
    input_tokens    { 500 }
    output_tokens   { 150 }
    cost            { 0.0123 }
    requested_by_id { create(:user).id }
    funded_by_id    { create(:user).id }
    asset_type      { "SceneSummary" }
    asset_id        { create(:scene_summary).id }
    created_at      { Time.current }
  end
end
