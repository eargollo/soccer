# frozen_string_literal: true

module ApplicationHelper
  # Standard button classes for primary actions (emerald/lime color scheme)
  def button_primary_classes(additional_classes: "")
    base_classes = "rounded-md bg-emerald-600 px-3 py-2 text-sm font-semibold text-white shadow-sm " \
                   "hover:bg-emerald-500 focus-visible:outline focus-visible:outline-2 " \
                   "focus-visible:outline-offset-2 focus-visible:outline-lime-400 transition-colors"
    [base_classes, additional_classes].compact_blank.join(" ")
  end

  # Generic sort link for teams page (no sorting functionality yet)
  def sort_link(column:, label:) # rubocop:disable Lint/UnusedMethodArgument
    # For now, just return the label as plain text
    # TODO: Add sorting functionality if needed
    label
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
    if params[:id].present? && controller_name == "seasons"
      # Find season directly by ID - simpler and more direct
      # The season will have the league association, so we don't need to go through league first
      return Season.find_by(id: params[:id])
    end

    # If viewing a league, get its target season
    if current_league
      target = current_league.seasons.where(active: true).order(:year).last
      return target if target.present?

      return current_league.seasons.order(year: :desc).first
    end

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
      # Links to matches - season-scoped if viewing a season, league-scoped otherwise
      # Check if we're currently viewing a season page
      viewing_season = params[:id].present? && controller_name == "seasons"

      if viewing_season && season && league
        # We're viewing a specific season, link to that season's matches
        league_season_matches_path(league, season)
      elsif league
        # We're in a league context but not viewing a specific season
        league_matches_path(league)
      else
        # No league context
        matches_path
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
    base_classes = "hover:text-lime-300 transition-colors"
    active_classes = active ? "border-b-2 border-lime-400" : ""
    [base_classes, active_classes, additional_classes].compact_blank.join(" ")
  end

  # Get CSS classes for dropdown menu item
  def dropdown_item_classes(active: false)
    base_classes = "block px-4 py-2 text-sm text-gray-900 hover:bg-emerald-50"
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
