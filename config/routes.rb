Rails.application.routes.draw do
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
    end
    resources :games, only: %i[index new create show edit update] do
      member do
        patch :toggle_sheets_hidden
      end
      resources :scenes, only: %i[index new create show] do
        member do
          patch :resolve
          post :toggle_notification_preference
        end
        resources :posts, only: %i[create edit update]
        resource :participants, only: %i[edit update], controller: "scene_participants" do
          post :join, on: :collection
        end
      end
      resource :player_management, only: %i[show], controller: "player_management" do
        resources :invitations, only: %i[create destroy]
        resources :game_members, only: %i[update]
      end
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

  root "games#index"
end
