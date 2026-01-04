# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "seasons#index"

  resources :simulations, only: %i[index create new show] do
    resources :teams, only: %i[show], controller: "simulations/teams"
  end
  resources :admin_leagues, only: %i[index show new create]
  resources :admin_seasons, only: %i[update]
  resources :teams, only: %i[index show]

  resources :leagues, only: %i[index show] do
    resources :seasons, only: %i[index show], controller: "leagues/seasons" do
      resources :matches, only: %i[index], controller: "leagues/seasons/matches"
      collection do
        get "list(:id)", to: "leagues/seasons#list", as: :list
      end
    end
    # Redirect /leagues/:league_id/matches to target season's matches for backward compatibility
    get "/matches", to: redirect { |params, request|
      league = League.find_by(id: params[:league_id])
      if league
        season = league.target_season
        if season
          round_param = request.query_parameters[:round] ? "?round=#{request.query_parameters[:round]}" : ""
          "/leagues/#{league.id}/seasons/#{season.id}/matches#{round_param}"
        else
          "/leagues/#{league.id}/seasons"
        end
      else
        "/leagues"
      end
    }
    resources :standings, only: %i[index], controller: "leagues/standings" do
      collection do
        get :list
      end
    end
  end

  # Keep non-nested routes for backward compatibility (can be removed later)
  resources :seasons, only: %i[index show] do
    collection do
      get "list(:id)", to: "seasons#list", as: :list
    end
  end
  # Redirect /matches to target season's matches for backward compatibility
  get "/matches", to: redirect { |_params, request|
    target_season = Season.target_season
    if target_season && target_season.league
      round_param = request.query_parameters[:round] ? "?round=#{request.query_parameters[:round]}" : ""
      "/leagues/#{target_season.league.id}/seasons/#{target_season.id}/matches#{round_param}"
    else
      "/leagues"
    end
  }

  resources :simulation_standings, only: %i[show], controller: "simulation_standings"

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
