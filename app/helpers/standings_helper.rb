# frozen_string_literal: true

module StandingsHelper
  def sort_link(column:, label:, league_id: nil, league: false)
    sort_direction = column == params[:column] ? next_sort_direction : "desc"

    if league
      link_to(label, list_league_standings_path(league_id: league_id, column:, direction: sort_direction))
    else
      link_to(label, list_standings_path(column:, direction: sort_direction))
    end
  end

  def sort_indicator
    content = content_tag(
      :path,
      nil,
      stroke: "currentColor",
      stroke_linecap: "round",
      stroke_linejoin: "round",
      stroke_width: 2,
      d: "m1 1 5.326 5.7a.909.909 0 0 0 1.348 0L13 1"
    )

    if params[:direction] == "asc"
      content = content_tag(
        :path,
        nil,
        stroke: "currentColor",
        stroke_linecap: "round",
        stroke_linejoin: "round",
        stroke_width: 2,
        d: "M13 7 7.674 1.3a.91.91 0 0 0-1.348 0L1 7"
      )
    end

    content_tag(:svg,
                content,
                class: "h-4 w-4 text-right tracking-wider",
                aria_hidden: true,
                xmlns: "http://www.w3.org/2000/svg",
                fill: "none",
                viewBox: "0 0 14 8")
  end

  def next_sort_direction
    params[:direction] == "asc" ? "desc" : "asc"
  end
end
