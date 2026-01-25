# frozen_string_literal: true

module Admin
  class FeatureFlagsController < AdminController
    def index
      @config = Rails.application.config.probability
    end
  end
end
