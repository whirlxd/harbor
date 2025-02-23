class AdminConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin?
  end
end

Rails.application.routes.draw do
  constraints AdminConstraint do
    mount Avo::Engine, at: Avo.configuration.root_path
    mount GoodJob::Engine => "good_job"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "static_pages#index"

  resources :static_pages, only: [ :index ] do
    collection do
      get :project_durations
    end
  end

  get "/auth/slack", to: "sessions#new", as: :slack_auth
  get "/auth/slack/callback", to: "sessions#create"
  delete "signout", to: "sessions#destroy", as: "signout"

  resources :leaderboards, only: [ :index ]

  # Nested under users for admin access
  resources :users, only: [] do
    get "settings", on: :member, to: "users#edit"
  end

  # Namespace for current user actions
  get "my/settings", to: "users#edit", as: :my_settings
  patch "my/settings", to: "users#update"

  post "/slack/commands", to: "sailors_log#create"
end
