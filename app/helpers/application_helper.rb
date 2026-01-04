# frozen_string_literal: true

module ApplicationHelper # rubocop:disable Metrics/ModuleLength
  # Standard button classes for primary actions (emerald/lime color scheme)
  def button_primary_classes(additional_classes: "")
    base_classes = "rounded-md bg-emerald-600 px-3 py-2 text-sm font-semibold text-white shadow-sm " \
                   "hover:bg-emerald-500 focus-visible:outline focus-visible:outline-2 " \
                   "focus-visible:outline-offset-2 focus-visible:outline-lime-400 transition-colors"
    [base_classes, additional_classes].compact_blank.join(" ")
  end

  # Get current league from URL only (no session, no fallback queries)
  def current_league
    return nil if params[:league_id].blank?

    League.find_by(id: params[:league_id])
  end

  # Get all leagues, cached to avoid queries on every page load
  def all_leagues
    Rails.cache.fetch('all_leagues', expires_in: 1.hour) do
      League.order(:name).to_a
    end
  end

  # Get current season based on context:
  # - If viewing a season page: return that season
  # - If viewing a league page: return league's target season
  # - Otherwise: return global target season
  def current_season # rubocop:disable Metrics/AbcSize
    # If viewing a specific season (nested or not)
    # Check if we're in a nested route like /leagues/:league_id/seasons/:id/matches
    # In this case, params[:season_id] contains the season ID when controller is "matches"
    if controller_name == "seasons" && params[:id].present?
      # Direct season view - params[:id] is the season ID
      return Season.find_by(id: params[:id])
    elsif controller_name == "matches" && params[:season_id].present?
      # Season-scoped matches - params[:season_id] is the season ID
      return Season.find_by(id: params[:season_id])
    end

    # If viewing a league, get its target season
    return current_league.target_season if current_league

    # Fallback to global target season
    Season.target_season
  end

  # Menu path helper - returns contextual routes based on league/season
  def menu_path_for(menu_item, league: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    league ||= current_league
    season = current_season

    case menu_item.to_sym
    when :classificacao
      # Links to season standings
      if season && league
        league_season_path(league, season)
      elsif season
        season_path(season)
      elsif league
        # Fallback to league's target season
        target = league.seasons.where(active: true).order(:year).last || league.seasons.order(year: :desc).first
        target ? league_season_path(league, target) : league_path(league)
      else
        root_path
      end
    when :tabela
      # Links to matches - always use league/season path
      # Prefer season-scoped if we have a season, otherwise use league's target season
      if season && league
        # We have both season and league, use season-scoped matches
        league_season_matches_path(league, season)
      elsif league
        # We have league but no season, use league's target season
        target_season = league.target_season
        if target_season
          league_season_matches_path(league, target_season)
        else
          # No target season, redirect to league seasons
          league_seasons_path(league)
        end
      else
        # No league context - find target season and its league
        target_season = Season.target_season
        if target_season&.league
          league_season_matches_path(target_season.league, target_season)
        else
          # Ultimate fallback - redirect to leagues
          leagues_path
        end
      end
    when :ranking, :pontos
      # Ranking dropdown and Pontos submenu - both link to aggregated points
      if league
        league_standings_path(league)
      else
        leagues_path
      end
    when :temporadas
      if league
        league_seasons_path(league)
      else
        root_path
      end
    when :times
      # Teams - same route for now (TODO: Create league-scoped teams route if needed)
      teams_path
    else
      '#'
    end
  end

  # Get CSS classes for menu item based on active state
  def menu_item_classes(active:, additional_classes: "")
    base_classes = "hover:text-lime-300 transition-colors duration-200 focus:outline-none focus:ring-2 " \
                   "focus:ring-lime-400 focus:ring-offset-2 focus:ring-offset-emerald-700 rounded-sm px-1"
    active_classes = active ? "border-b-2 border-lime-400" : ""
    [base_classes, active_classes, additional_classes].compact_blank.join(" ")
  end

  # Get CSS classes for dropdown menu item
  def dropdown_item_classes(active: false)
    base_classes = "block px-4 py-2 text-sm text-gray-900 hover:bg-emerald-50 transition-colors " \
                   "duration-150 focus:outline-none focus:bg-emerald-100 focus:ring-2 " \
                   "focus:ring-emerald-500 focus:ring-inset"
    active_classes = active ? "bg-emerald-100 font-semibold" : ""
    [base_classes, active_classes].compact_blank.join(" ")
  end

  # Check if menu item is active based on controller/action
  def menu_item_active?(menu_item) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    case menu_item.to_sym
    when :classificacao
      # Active when viewing a season page (standings view)
      controller_name == "seasons" && action_name == "show"
    when :tabela
      # Active when viewing matches (league-scoped or season-scoped)
      controller_name == "matches"
    when :ranking, :pontos
      # Active when viewing league standings (aggregated points across all seasons)
      controller_name == "standings" && params[:league_id].present?
    when :temporadas
      # Active when viewing seasons list (index) or league show page (which shows seasons)
      (controller_name == "seasons" && action_name == "index") ||
        (controller_name == "leagues" && action_name == "show")
    when :times
      # Active when viewing teams
      controller_name == "teams"
    else
      false
    end
  end
end
