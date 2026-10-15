Rails.application.routes.draw do
  root "work_orders#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get  "login",    to: "sessions#new"
  post "login",    to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Registration
  get  "register", to: "registrations#new"
  post "register", to: "registrations#create"

  # Work Orders with One-Click Transition route
  resources :work_orders do
    member do
      patch :transition
    end
  end
end
