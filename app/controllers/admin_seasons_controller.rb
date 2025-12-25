# frozen_string_literal: true

class AdminSeasonsController < AdminController
  def update # rubocop:disable Metrics/AbcSize
    Rails.logger.info("Updating season #{params[:id]}")
    season = Season.find_by(id: params[:id])

    unless season
      flash[:error] = "Season not found" # rubocop:disable Rails/I18nLocaleTexts
      redirect_to admin_leagues_path
      return
    end

    case params[:type]
    when 'sync'
      Rails.logger.info("Syncing season #{params[:id]}")
      season.seed
    when 'async'
      Rails.logger.info("Scheduling async update for season #{params[:id]}")
      UpdateLeagueJob.perform_later(season.id)
    when 'close'
      Rails.logger.info("Closing season #{params[:id]}")
      if season.active
        season.close
      else
        season.update!(active: true)
      end
    end

    redirect_to admin_leagues_path
  end
end
