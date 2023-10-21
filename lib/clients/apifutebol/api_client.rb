class Client
  def matches
    filename = "#{Rails.root}/lib/clients/apifutebol/matches.json"
    file = File.read(filename)
    JSON.parse(file)
  end
end
