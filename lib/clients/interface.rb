# frozen_string_literal: true

module Clients
  module Interface
    def matches(*)
      raise "Not implemented"
    end

    def team(_id)
      raise "Not implemented"
    end
  end

  # Needs of a match:
  # - date
  # - round
  # - home_team_reference
  # - away_team_reference
  # - home_goals
  # - away_goals
  # - status
  # - reference

  # Needs of a team:
  # - name
  # - code
  # - founded
  # - reference
  # - logo
end
