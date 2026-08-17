# frozen_string_literal: true

require "swagger_helper"

# Pages are readable by any non-banned member (PagePolicy#viewable?) and
# writable only by the GM (PagePolicy#manage?); a draft page is GM-only to
# read even though the resource as a whole is member-readable
# (PagePolicy#show?). Every create/update also proves version attribution: a
# PageVersion row is written with edited_by_id == the token's user id,
# showing Current.user was set from the token before the save happened.
RSpec.describe "api/pages", type: :request do
  let(:game) { create(:game) }
  let(:gm_user) { create(:user, :with_profile) }
  let!(:gm_membership) { create(:game_member, :game_master, game: game, user: gm_user) }
  let(:gm_token) { create(:api_token, user: gm_user, game: game, scope: "api") }

  let(:member_user) { create(:user, :with_profile) }
  let!(:member_membership) { create(:game_member, game: game, user: member_user) }
  let(:member_token) { create(:api_token, user: member_user, game: game, scope: "api") }

  let(:banned_user) { create(:user, :with_profile) }
  let!(:banned_membership) { create(:game_member, :banned, game: game, user: banned_user) }
  let(:banned_token) { create(:api_token, user: banned_user, game: game, scope: "api") }

  let!(:published_page) { create(:page, game: game, title: "Existing", editor: gm_user) }
  let!(:draft_page) { create(:page, game: game, title: "Draft", draft: true, editor: gm_user) }

  path "/api/pages" do
    get "List pages" do
      tags "Pages"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :title, in: :query, required: false, schema: { type: :string },
                description: "Case-insensitive substring match on the page title."
      parameter name: :created_by, in: :query, required: false, schema: { type: :integer },
                description: "Keep only pages created by this user id (the editor of the page's first version; immutable across later versions)."
      parameter name: :edited_by, in: :query, required: false, schema: { type: :integer },
                description: "Keep only pages this user id authored any version of (creator or later editor)."
      parameter name: :since, in: :query, required: false, schema: { type: :string, format: "date-time" },
                description: "ISO-8601 timestamp; keep only pages created at or after it."
      parameter name: :order, in: :query, required: false,
                schema: { type: :string, enum: %w[newest oldest], default: "newest" },
                description: "Sort by creation time. Defaults to newest first."

      let(:title) { nil }
      let(:created_by) { nil }
      let(:edited_by) { nil }
      let(:since) { nil }
      let(:order) { nil }

      response "200", "a non-GM member sees only published pages, never drafts" do
        let(:Authorization) { "Bearer #{member_token.token}" }
        run_test! do |response|
          slugs = JSON.parse(response.body).map { |page| page["slug"] }
          expect(slugs).to include(published_page.slug)
          expect(slugs).not_to include(draft_page.slug)
        end
      end

      response "200", "the GM sees published pages and their own drafts" do
        let(:Authorization) { "Bearer #{gm_token.token}" }
        run_test! do |response|
          slugs = JSON.parse(response.body).map { |page| page["slug"] }
          expect(slugs).to include(published_page.slug, draft_page.slug)
        end
      end

      response "401", "no token" do
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "banned member is denied" do
        let(:Authorization) { "Bearer #{banned_token.token}" }
        run_test!
      end
    end

    post "Create a page" do
      tags "Pages"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :page, in: :body, schema: { "$ref" => "#/components/schemas/page_input" }

      response "201", "page created" do
        let(:page) { { page: { title: "New Page", body: "# Body" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/page"

        run_test! do |response|
          body = JSON.parse(response.body)
          created = Page.find_by!(slug: body["slug"])
          version = created.page_versions.order(:created_at).last

          expect(version).to be_present
          expect(version.edited_by_id).to eq(gm_user.id)
        end
      end

      response "401", "no token" do
        let(:page) { { page: { title: "New Page", body: "# Body" } } }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "active non-GM member is denied" do
        let(:page) { { page: { title: "New Page", body: "# Body" } } }
        let(:Authorization) { "Bearer #{member_token.token}" }
        run_test!
      end

      response "422", "blank title is rejected" do
        let(:page) { { page: { title: "", body: "# Body" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end
    end
  end

  path "/api/pages/{slug}" do
    get "Show a page" do
      tags "Pages"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :slug, in: :path, type: :string

      response "200", "published page found" do
        let(:slug) { published_page.slug }
        let(:Authorization) { "Bearer #{member_token.token}" }
        schema "$ref" => "#/components/schemas/page"
        run_test!
      end

      response "401", "no token" do
        let(:slug) { published_page.slug }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "banned member is denied" do
        let(:slug) { published_page.slug }
        let(:Authorization) { "Bearer #{banned_token.token}" }
        run_test!
      end

      response "403", "a draft page is denied to a non-GM member" do
        let(:slug) { draft_page.slug }
        let(:Authorization) { "Bearer #{member_token.token}" }
        run_test!
      end

      response "404", "unknown slug" do
        let(:slug) { "unknown-slug-000" }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end
    end

    patch "Update a page" do
      tags "Pages"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_token: [] } ]
      parameter name: :slug, in: :path, type: :string
      parameter name: :page, in: :body, schema: { "$ref" => "#/components/schemas/page_input" }

      response "200", "page updated" do
        let(:slug) { published_page.slug }
        let(:page) { { page: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/page"

        run_test! do
          reloaded = published_page.reload
          version = reloaded.page_versions.order(:created_at).last

          expect(version).to be_present
          expect(version.edited_by_id).to eq(gm_user.id)
        end
      end

      response "401", "no token" do
        let(:slug) { published_page.slug }
        let(:page) { { page: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { nil }
        run_test! do |response|
          expect(response.body).to be_empty
        end
      end

      response "403", "active non-GM member is denied" do
        let(:slug) { published_page.slug }
        let(:page) { { page: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{member_token.token}" }
        run_test!
      end

      response "404", "unknown slug" do
        let(:slug) { "unknown-slug-000" }
        let(:page) { { page: { title: "Updated title", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end

      response "422", "blank title is rejected" do
        let(:slug) { published_page.slug }
        let(:page) { { page: { title: "", body: "# Updated" } } }
        let(:Authorization) { "Bearer #{gm_token.token}" }
        schema "$ref" => "#/components/schemas/errors"
        run_test!
      end
    end
  end
end
