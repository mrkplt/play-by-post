# frozen_string_literal: true

require "swagger_helper"

# Notebook entries are GM-only in every direction (NotebookEntryPolicy). An
# active non-GM member's token is denied every action here, and so is a
# banned GM's token — the active-GM gate reads role AND status. Every
# create/update also proves version attribution: a NotebookEntryVersion row
# is written with edited_by_id == the token's user id, showing Current.user
# was set from the token before the save happened.
RSpec.describe "api/notebook_entries", type: :request do
  let(:game) { create(:game) }
  let(:gm_user) { create(:user, :with_profile) }
  let!(:gm_membership) { create(:game_member, :game_master, game: game, user: gm_user) }
  let(:gm_token) { create(:api_token, user: gm_user, game: game, scope: "api") }

  let(:other_user) { create(:user, :with_profile) }
  let!(:other_membership) { create(:game_member, game: game, user: other_user) }
  let(:other_token) { create(:api_token, user: other_user, game: game, scope: "api") }

  let(:banned_gm_user) { create(:user, :with_profile) }
  let!(:banned_gm_membership) do
    create(:game_member, :game_master, :banned, game: game, user: banned_gm_user)
  end
  let(:banned_gm_token) { create(:api_token, user: banned_gm_user, game: game, scope: "api") }

  let!(:existing_entry) { create(:notebook_entry, game: game, title: "Existing", editor: gm_user) }

  path "/api/notebook_entries" do
    get "List notebook entries" do
      tags "Notebook Entries"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :title, in: :query, required: false, schema: { type: :string },
                description: "Case-insensitive substring match on the entry title."
      parameter name: :created_by, in: :query, required: false, schema: { type: :integer },
                description: "Keep only entries created by this user id (the editor of the entry's first version; immutable across later versions)."
      parameter name: :edited_by, in: :query, required: false, schema: { type: :integer },
                description: "Keep only entries this user id authored any version of (creator or later editor)."
      parameter name: :since, in: :query, required: false, schema: { type: :string, format: "date-time" },
                description: "ISO-8601 timestamp; keep only entries created at or after it."
      parameter name: :order, in: :query, required: false,
                schema: { type: :string, enum: %w[newest oldest], default: "newest" },
                description: "Sort by creation time. Defaults to newest first."

      let(:title) { nil }
      let(:created_by) { nil }
      let(:edited_by) { nil }
      let(:since) { nil }
      let(:order) { nil }

      response "200", "notebook entries for the token's game" do
        let(:Authorization) { "Bearer #{gm_token.token}" }
        run_test!
      end

      response "401", "no token" do
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "active non-GM member is denied" do
        let(:Authorization) { "Bearer #{other_token.token}" }
        run_test!
      end

      response "403", "banned GM is denied" do
        let(:Authorization) { "Bearer #{banned_gm_token.token}" }
        run_test!
      end
    end

    post "Create a notebook entry" do
      tags "Notebook Entries"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :notebook_entry, in: :body, schema: { "$ref" => "#/components/schemas/notebook_entry_input" }

      response "201", "notebook entry created" do
        let(:notebook_entry) { { notebook_entry: { title: "New Idea", body: "# Body" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/notebook_entry"

        run_test! do |response|
          body = JSON.parse(response.body)
          created = NotebookEntry.find_by!(slug: body["slug"])
          version = created.notebook_entry_versions.order(:created_at).last

          expect(version).to be_present
          expect(version.edited_by_id).to eq(gm_user.id)
          # No status supplied: the entry lands in the default `new` lane.
          expect(body["status"]).to eq("new")
        end
      end

      response "201", "notebook entry created in a chosen lane" do
        let(:notebook_entry) { { notebook_entry: { title: "New Idea", body: "# Body", status: "expand" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/notebook_entry"

        run_test! do |response|
          expect(JSON.parse(response.body)["status"]).to eq("expand")
        end
      end

      response "400", "an out-of-range status is rejected" do
        let(:notebook_entry) { { notebook_entry: { title: "New Idea", body: "# Body", status: "nonsense" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end

      response "401", "no token" do
        let(:notebook_entry) { { notebook_entry: { title: "New Idea", body: "# Body" } } }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "active non-GM member is denied" do
        let(:notebook_entry) { { notebook_entry: { title: "New Idea", body: "# Body" } } }
        let(:Authorization) { "Bearer #{other_token.token}" }
        run_test!
      end

      response "403", "banned GM is denied" do
        let(:notebook_entry) { { notebook_entry: { title: "New Idea", body: "# Body" } } }
        let(:Authorization) { "Bearer #{banned_gm_token.token}" }
        run_test!
      end

      response "422", "blank title is rejected" do
        let(:notebook_entry) { { notebook_entry: { title: "", body: "# Body" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end
    end
  end

  path "/api/notebook_entries/{slug}" do
    get "Show a notebook entry" do
      tags "Notebook Entries"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :slug, in: :path, type: :string

      response "200", "notebook entry found" do
        let(:slug) { existing_entry.slug }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/notebook_entry"
        run_test!
      end

      response "401", "no token" do
        let(:slug) { existing_entry.slug }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "active non-GM member is denied" do
        let(:slug) { existing_entry.slug }
        let(:Authorization) { "Bearer #{other_token.token}" }
        run_test!
      end

      response "403", "banned GM is denied" do
        let(:slug) { existing_entry.slug }
        let(:Authorization) { "Bearer #{banned_gm_token.token}" }
        run_test!
      end

      response "404", "unknown slug" do
        let(:slug) { "unknown-slug-000" }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end
    end

    patch "Update a notebook entry" do
      tags "Notebook Entries"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :slug, in: :path, type: :string
      parameter name: :notebook_entry, in: :body, schema: { "$ref" => "#/components/schemas/notebook_entry_input" }

      response "200", "notebook entry updated" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/notebook_entry"

        run_test! do
          entry = existing_entry.reload
          version = entry.notebook_entry_versions.order(:created_at).last

          expect(version).to be_present
          expect(version.edited_by_id).to eq(gm_user.id)
        end
      end

      response "200", "notebook entry moved to another lane" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { status: "done" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/notebook_entry"

        run_test! do |response|
          expect(JSON.parse(response.body)["status"]).to eq("done")
        end
      end

      response "400", "an out-of-range status is rejected" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { status: "nonsense" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end

      response "401", "no token" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "active non-GM member is denied" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{other_token.token}" }
        run_test!
      end

      response "403", "banned GM is denied" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{banned_gm_token.token}" }
        run_test!
      end

      response "404", "unknown slug" do
        let(:slug) { "unknown-slug-000" }
        let(:notebook_entry) { { notebook_entry: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end

      response "422", "blank title is rejected" do
        let(:slug) { existing_entry.slug }
        let(:notebook_entry) { { notebook_entry: { title: "", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end
    end
  end
end
