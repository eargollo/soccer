# frozen_string_literal: true

# Soccer API Client
class Client
  def league
    filename = File.expand_path('matches.json', File.dirname(__FILE__))
    file = File.read(filename)
    data = JSON.parse(file)
    ImportLeague.new(data)
  end
end

class ImportLeague
  LEAGUE = 216
  attr_reader :id, :name, :teams, :matches

  def initialize(data)
    raise "Error: more than one league in payload" if data.size != 1

    @id = data[0]["league_id"]
    @name = data[0]["league_name"]

    raise "Error: wrong league id (league '#{@name}'), expected #{LEAGUE}, got #{@id}" if @id != LEAGUE

    load_teams_matches(data[0]["stage"][0]["matches"])
  end

  private

  def load_teams_matches(data) # rubocop:disable all
    @teams = []
    team_hash = {}
    @matches = data.map do |m|
      match = ImportMatch.new(m)
      if team_hash[match.home_team_id].nil?
        team_hash[match.home_team_id] = 0
        @teams << ImportTeam.new(m["teams"]["home"])
      end
      if team_hash[match.away_team_id].nil?
        team_hash[match.away_team_id] = 0
        @teams << ImportTeam.new(m["teams"]["away"])
      end
      match
    end
  end
end

class ImportMatch
  attr_accessor :round
  attr_reader :id, :date, :status, :home_team_id, :home_team, :away_team_id, :away_team, :home_goals,
              :away_goals, :result

  def initialize(data) # rubocop:disable Metrics/AbcSize
    @id = data["id"]
    @date = to_date(data["date"], data["time"])
    @status = data["status"]
    @home_team_id = data["teams"]["home"]["id"]
    @home_team = data["teams"]["home"]["name"]
    @away_team_id = data["teams"]["away"]["id"]
    @away_team = data["teams"]["away"]["name"]
    @home_goals = data["goals"]["home_ft_goals"]
    @away_goals = data["goals"]["away_ft_goals"]
    @result = data["winner"]
  end
end

class ImportTeam
  attr_reader :id, :name

  def initialize(data)
    @id = data["id"]
    @name = data["name"]
  end
end

def to_date(date, time)
  day, month, year = date.split("/")
  hour, minute = time.split(":")
  DateTime.new(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, 0, '-03:00')
end
