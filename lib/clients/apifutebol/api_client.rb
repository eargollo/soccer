# frozen_string_literal: true

# Soccer API Client
class Client
  def matches
    filename = File.expand_path('matches.json', File.dirname(__FILE__))
    file = File.read(filename)
    JSON.parse(file)
  end
end
