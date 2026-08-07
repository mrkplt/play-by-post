# typed: true

require "json"

namespace :fizzy do
  desc "Import feedback ideas from a JSON export into the Fizzy board as cards"
  task import_ideas: :environment do
    path = ENV.fetch("FILE", "feedback-ideas-2026-08-06.json")
    data = JSON.parse(File.read(path))
    discarded_ids = (data["discarded"] || []).map { |entry| entry["id"] }

    (data["categories"] || {}).each do |category, entries|
      (entries || []).each do |entry|
        next if discarded_ids.include?(entry["id"])

        lines = [ entry["body"].to_s ]
        lines.unshift("Category: #{category}")
        lines << "Submitted from: #{entry["url"]}" if entry["url"].present?
        lines << "Submitted by: #{entry["email"]}"

        location = FizzySweepService.post_card(
          title: "Feedback ##{entry["id"]}",
          description: lines.join("\n\n")
        )
        puts "Created Feedback ##{entry["id"]} -> #{location}"
      end
    end
  end
end
