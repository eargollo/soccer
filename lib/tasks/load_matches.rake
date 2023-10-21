require "#{Rails.root}/lib/clients/apifutebol/api_client.rb"

namespace :import do
  desc "Import championship matches"
  task :matches => :environment do
    matches = Client.new.matches

    puts "Importing league '#{matches[0]["league_name"]}'(id=#{matches[0]["league_id"]})..."
    list = matches[0]["stage"][0]["matches"]
    puts "Matches: #{list.size}"
    list.each do |m|
      puts "Importing #{m["teams"]["home"]["name"]} x #{m["teams"]["away"]["name"]} at #{m["date"]}..."
      match = Match.find_by(reference: m["id"])
      if !match.nil?
        puts "Match already imported, skipping..."
        next
      end

      team_home = find_or_create(m["teams"]["home"])
      team_away = find_or_create(m["teams"]["away"])
    end
  end
end

def find_or_create(data)
  team = Team.find_by(reference: data["id"])
  if team.nil?
    puts "Creating team #{data["name"]}..."
    team = Team.create(name: data["name"], reference: data["id"])
  end
  team
end
