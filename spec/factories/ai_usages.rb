FactoryBot.define do
  factory :ai_usage do
    feature       { "inbound_email" }
    model_used    { "google/gemma-3-4b-it:free" }
    input_tokens  { 120 }
    output_tokens { 40 }
    created_at    { Time.current }
  end
end
