# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"

# Stimulus controllers
pin "controllers", to: "controllers/index.js"
pin "controllers/application", to: "controllers/application.js"
pin "controllers/dropdown_controller", to: "controllers/dropdown_controller.js"
pin "controllers/mobile_menu_controller", to: "controllers/mobile_menu_controller.js"
