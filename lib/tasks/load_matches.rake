# frozen_string_literal: true

require Rails.root.join("lib/clients/apifutebol/api_client.rb")

namespace :import do
  desc "Import championship matches"
  task matches: :environment do
    matches = Client.new.matches

    puts "Importing league '#{matches[0]['league_name']}'(id=#{matches[0]['league_id']})..."
    list = matches[0]["stage"][0]["matches"]
    puts "Matches: #{list.size}"
    list.each do |m|
      puts "Importing #{m['teams']['home']['name']} x #{m['teams']['away']['name']} at #{m['date']} #{m['time']}..."
      match = Match.find_by(reference: m["id"])
      unless match.nil?
        puts "Match already imported, skipping..."
        next
      end

      team_home = find_or_create(m["teams"]["home"])
      team_away = find_or_create(m["teams"]["away"])

      date = to_date(m["date"], m["time"])
      Match.create(
        date:,
        team_home:,
        team_away:,
        status: m["status"],
        home_goals: m["goals"]["home_ft_goals"],
        away_goals: m["goals"]["away_ft_goals"],
        result: m["winner"],
        reference: m["id"]
      )
    end
  end
end

def find_or_create(data)
  team = Team.find_by(reference: data["id"])
  if team.nil?
    puts "Creating team #{data['name']}..."
    team = Team.create(name: data["name"], reference: data["id"])
  end
  team
end

def to_date(date, time)
  day, month, year = date.split("/")
  hour, minute = time.split(":")
  DateTime.new(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i, 0, '-03:00')
end
