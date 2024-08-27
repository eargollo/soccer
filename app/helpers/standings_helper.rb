# frozen_string_literal: true

module StandingsHelper
  def sort_link(column:, label:)
    link_to(label, list_standings_path(column:))
  end
end
