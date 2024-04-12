# frozen_string_literal: true

class League < ApplicationRecord
  has_many :seasons, dependent: :destroy
  has_many :matches, through: :seasons
end
