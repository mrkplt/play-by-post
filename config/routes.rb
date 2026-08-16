Rails.application.routes.draw do
  # Resend inbound email webhook (custom ActionMailbox ingress)
  post "/mail/inbound" =>
    "action_mailbox/ingresses/resend/inbound_emails#create",
    as: :rails_resend_inbound_emails

  # Deploy relay: GitHub Actions posts here after a new image is built; we
  # forward the trigger to Coolify over the internal network (Coolify is not
  # exposed to the internet).
  post "/webhooks/deploy" => "webhooks/deploy#create", as: :deploy_webhook

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  get "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  authenticate :user do
    resource :feedback, only: %i[create]
    resource :profile, only: %i[show edit update], controller: "profiles" do
      post :toggle_hide_ooc, on: :collection
      post :export_all, on: :collection
      resources :api_tokens, only: %i[create destroy], module: :profiles
    end
    resources :games, only: %i[index new create show edit update destroy] do
      # Kept as toggle_*_game_path on the game itself — the setting switches
      # read as part of the game, while the actions live in their own
      # controller so GamesController stays about games.
      member do
        patch :toggle_sheets_hidden, to: "games/settings#sheets_hidden"
        patch :toggle_images_disabled, to: "games/settings#images_disabled"
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
      end
      resources :characters, only: %i[new create show edit update] do
        member do
          patch :archive
          patch :restore
        end
        resources :character_versions, only: %i[show], path: "versions"
      end
    end
  end

  # Machine-auth surface (bearer ApiToken, no session). The token carries the
  # game, so no :game_id in the path.
  get "/rss/feed", to: "rss#feed", defaults: { format: :rss }

  root "games#index"
end
