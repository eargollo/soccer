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
if User.find_by(email: Rails.application.credentials.admin_user.email).nil?
  User.create(
    name: Rails.application.credentials.admin_user.name,
    email: Rails.application.credentials.admin_user.email,
    password: Rails.application.credentials.admin_user.password,
    password_confirmation: Rails.application.credentials.admin_user.password
  )
end
