Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/homepage")
  get "/homepage", to: "homepage#show", as: :homepage

  resources :people, only: [:index, :show, :update]

  resources :entries, only: [:new, :create, :show, :edit, :update] do
    collection do
      get :preview, action: :show_preview
      post :preview, action: :create_preview
      post :resolve_person
      post :create_person
      get :drafts
      delete :draft, action: :discard_draft
    end

    member do
      post :preview, action: :create_preview_update
    end
  end

  get "/search", to: "search#show", as: :search
end
