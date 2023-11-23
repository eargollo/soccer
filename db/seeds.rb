# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed admin user
if User.find_by(email: ENV.fetch('ADMIN_USER_EMAIL', nil)).nil?
  User.create(
    name: ENV.fetch('ADMIN_USER_NAME', nil),
    email: ENV.fetch('ADMIN_USER_EMAIL', nil),
    password: ENV.fetch('ADMIN_USER_PASSWORD', nil),
    password_confirmation: ENV.fetch('ADMIN_USER_PASSWORD', nil)
  )
end
