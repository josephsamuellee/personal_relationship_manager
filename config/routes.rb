Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/homepage")
  get "/homepage", to: "homepage#show", as: :homepage
  get "/timeline/:year", to: "timeline#show", as: :timeline

  resources :people, only: [ :index, :show, :update ]

  resources :entries, only: [ :new, :create, :show, :edit, :update ] do
    collection do
      get :preview, action: :show_preview
      post :preview, action: :create_preview
      post :resolve_person
      post :create_person
      post :replace_person_name
      get :drafts
      delete :draft, action: :discard_draft, as: :discard_draft
    end

    member do
      post :preview, action: :create_preview_update
    end
  end

  get "/search/entries", to: "search#entries", as: :search_entries
  get "/search", to: "search#show", as: :search

  get "/config", to: "config#show", as: :config
  patch "/config", to: "config#update"

  get "/homepage/upcoming_calendar_events", to: "upcoming_calendar_events#show", as: :upcoming_calendar_events

  get "/google_calendar/oauth/connect", to: "google_calendar_oauth#connect", as: :google_calendar_oauth_connect
  get "/google_calendar/oauth/callback", to: "google_calendar_oauth#callback", as: :google_calendar_oauth_callback
  delete "/google_calendar/oauth/disconnect", to: "google_calendar_oauth#disconnect", as: :google_calendar_oauth_disconnect
end
