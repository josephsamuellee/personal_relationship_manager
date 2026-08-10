Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/homepage")
  get "/homepage", to: "homepage#show", as: :homepage

  resources :people, only: [:index, :show, :update]

  resources :entries, only: [:new, :create, :show, :edit, :update] do
    collection do
      post :preview
      post :resolve_person
      post :create_person
    end

    member do
      post :preview, action: :preview_update
    end
  end

  get "/search", to: "search#show", as: :search
end
