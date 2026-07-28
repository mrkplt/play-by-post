Rails.application.routes.draw do
  # Resend inbound email webhook (custom ActionMailbox ingress)
  post "/mail/inbound" =>
    "action_mailbox/ingresses/resend/inbound_emails#create",
    as: :rails_resend_inbound_emails

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  get "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  authenticate :user do
    resource :profile, only: %i[show edit update], controller: "profiles" do
      post :toggle_hide_ooc, on: :collection
      post :export_all, on: :collection
      post :generate_rss_token, on: :collection
      delete :revoke_rss_token, on: :collection
    end
    resources :games, only: %i[index new create show edit update] do
      member do
        patch :toggle_sheets_hidden
        patch :toggle_images_disabled
        patch :toggle_ai_summaries_enabled
      end
      resources :scenes, only: %i[index new create show] do
        member do
          patch :resolve
          post :toggle_notification_preference
        end
        resource :scene_summary, only: %i[new create edit update destroy],
                                  controller: "scene_summaries"
        resources :posts, only: %i[create edit update] do
          member do
            post :mark_read
          end
          collection do
            patch :save_draft
            delete :discard_draft
          end
        end
        resource :participants, only: %i[edit update], controller: "scene_participants" do
          post :join, on: :collection
        end
      end
      resource :player_management, only: %i[show], controller: "player_management" do
        resources :invitations, only: %i[create destroy]
        resources :game_members, only: %i[update]
      end
      resource :export, only: %i[create], controller: "game_exports"
      resources :game_files, only: %i[index create destroy]
      resources :characters, only: %i[new create show edit update] do
        member do
          patch :archive
          patch :restore
        end
        resources :character_versions, only: %i[show], path: "versions"
      end
    end
  end

  # Campaign log index and RSS feed — accessible with RSS token (no session required)
  resources :games, only: [] do
    resources :scene_summaries, only: %i[index]
  end

  root "games#index"
end
