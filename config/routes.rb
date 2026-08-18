Rails.application.routes.draw do
  # Runtime modes (RUNTIME_MODE, read only through RuntimeMode): unset draws
  # everything; "web" draws the session/Devise surface; "api" draws the /api +
  # machine-auth surface. The gate is here at route-drawing — an undrawn route
  # is the boundary — never at controller/eager load. See lib/runtime_mode.rb.
  #
  # Shared infra routes below are drawn in EVERY mode on purpose:
  #   - GET /up  — the health check MUST answer in every mode, or an api-only
  #     (or web-only) container is reported unhealthy and never receives traffic.
  #   - POST /mail/inbound  — ActionMailbox ingress (Svix-signed, no session):
  #     a machine surface an api-mode process legitimately serves.
  #   - POST /webhooks/deploy  — deploy relay (bearer-secret, no session):
  #     likewise machine-auth, and any mode's container may receive the callback.

  # Shared: the health check answers in every mode.
  get "up" => "rails/health#show", as: :rails_health_check

  # Shared: machine-auth ingress/relay (no session) — drawn in every mode.
  # Resend inbound email webhook (custom ActionMailbox ingress).
  post "/mail/inbound" =>
    "action_mailbox/ingresses/resend/inbound_emails#create",
    as: :rails_resend_inbound_emails

  # Deploy relay: GitHub Actions posts here after a new image is built; we
  # forward the trigger to Coolify over the internal network (Coolify is not
  # exposed to the internet).
  post "/webhooks/deploy" => "webhooks/deploy#create", as: :deploy_webhook

  if RuntimeMode.api?
    # API-only surface. The docs mounts describe /api; the machine-auth RSS feed
    # and JSON data API are the api process's whole reason to exist.
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"

    # Machine-auth surface (bearer ApiToken, no session). The token carries the
    # game, so no :game_id in the path.
    get "/rss/feed", to: "rss#feed", defaults: { format: :rss }

    # JSON data API (bearer api-scoped ApiToken). CRU over the token's game's
    # pages and notebook entries, addressed by slug; no delete.
    namespace :api, defaults: { format: :json } do
      resources :pages, only: %i[index show create update], param: :slug
      resources :notebook_entries, only: %i[index show create update], param: :slug
    end
  end

  # Everything below is the web (session/Devise) surface — drawn only in web mode
  # (or when unset). An api-mode process draws none of it.
  if RuntimeMode.web?
    if Rails.env.development?
      mount LetterOpenerWeb::Engine, at: "/letter_opener"
    end

    devise_for :users, controllers: {
      sessions: "users/sessions"
    }

    get "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

    authenticate :user do
    resource :feedback, only: %i[create]
    resource :profile, only: %i[show edit update], controller: "profiles" do
      post :toggle_hide_ooc, on: :collection
      post :export_all, on: :collection
      resources :api_tokens, only: %i[create destroy], module: :profiles
      resources :images, only: %i[create update destroy], controller: "user_images"
    end
    resources :games, only: %i[index new create show edit update destroy] do
      # Kept as toggle_*_game_path on the game itself — the setting switches
      # read as part of the game, while the actions live in their own
      # controller so GamesController stays about games.
      member do
        patch :toggle_sheets_hidden, to: "games/settings#sheets_hidden"
        patch :toggle_ai_summaries_enabled, to: "games/settings#ai_summaries_enabled"
      end
      resources :scenes, only: %i[index new create show] do
        member do
          patch :resolve
          post :toggle_notification_preference
        end
        resource :scene_summary, only: %i[new create edit update destroy],
                                  controller: "scene_summaries" do
          # Namespaced under the summary: the editor autosaves the draft flag on
          # the summary's own row (its scene_id is uniquely indexed, so a summary
          # cannot hold a separate draft row), and publishing promotes it.
          patch :save_draft, to: "scene_summaries/drafts#save"
          patch :publish, to: "scene_summaries/drafts#publish"
        end
        resources :posts, only: %i[create edit update] do
          member do
            post :mark_read
          end
          # Kept as save_draft/discard_draft_game_scene_posts_path — the
          # composer autosaves to the same URLs; only the controller moved, so
          # PostsController stays about published posts.
          collection do
            patch :save_draft, to: "posts/drafts#save"
            delete :discard_draft, to: "posts/drafts#discard"
          end
        end
        resource :participants, only: %i[edit update], controller: "scene_participants" do
          post :join, on: :collection
        end
      end
      resource :player_management, only: %i[show], controller: "player_management" do
        resources :invitations, only: %i[create destroy] do
          post :resend, on: :member
        end
        resources :game_members, only: %i[update]
      end
      resource :export, only: %i[create], controller: "game_exports"
      resources :scene_summaries, only: %i[index]
      resources :game_files, only: %i[index create destroy]
      resources :pages, only: %i[new create show edit update destroy], param: :slug do
        # Namespaced under the page: the editor autosaves the draft flag on the
        # page's own row, and publishing promotes it. PagesController stays about
        # published pages, as PostsController does for posts.
        member do
          patch :save_draft, to: "pages/drafts#save"
          patch :publish, to: "pages/drafts#publish"
        end
        resources :page_versions, only: %i[show], path: "versions"
      end
      resources :game_links, only: %i[index new create edit update destroy]
      resources :content_templates, only: %i[index new create edit update destroy]
      resources :notebook_entries, only: %i[index new create edit update destroy], param: :slug do
        # Kept as move/promote_game_notebook_entry_path — the lane picker and
        # the promote button post to the same URLs; only the controller moved,
        # so NotebookEntriesController stays about editing entries.
        member do
          patch :move, to: "notebook_entries/lanes#move"
          post :promote, to: "notebook_entries/lanes#promote"
        end
        resources :notebook_entry_versions, only: %i[show], path: "versions"
      end
      resources :characters, only: %i[new create show edit update] do
        member do
          patch :archive
          patch :restore
        end
        resources :character_versions, only: %i[show], path: "versions"
        resources :images, only: %i[create update destroy], controller: "character_images"
      end
    end
    end

    root "games#index"
  end
end
