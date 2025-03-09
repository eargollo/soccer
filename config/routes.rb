# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  root "standings#index"

  resources :standings, only: %i[index show] do
    collection do
      get "list(:id)", to: "standings#list", as: :list
    end
  end
  resources :simulations, only: %i[index create new show] do
    resources :teams, only: %i[show], controller: "simulations/teams"
  end
  resources :matches, only: %i[index]
  resources :admin_leagues, only: %i[index show new create]
  resources :admin_seasons, only: %i[update]
  resources :teams, only: %i[index show]
  resources :leagues, only: %i[index show] do
    resources :standings, only: %i[index], controller: "league_standings" do
      collection do
        get :list
      end
    end
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
