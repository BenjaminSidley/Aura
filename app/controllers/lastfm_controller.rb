class LastfmController < ApplicationController
  before_action :require_login

  def recent
    unless current_user.lastfm_connected
      redirect_to root_path, alert: 'Connect your Last.fm account first.'
      return
    end

    client = LastfmClient.new(current_user)
    @tracks = client.recent_tracks(limit: 25)
  rescue => e
    Rails.logger.error("[LastfmController#recent] #{e.class}: #{e.message}")
    @tracks = []
    flash.now[:alert] = 'Could not load recent tracks from Last.fm.'
  end

  # Search page - shows a search box and results when q is present
  def search
    @query = params[:q]&.to_s
    @tracks = []
    if @query.present?
      client = LastfmClient.new(current_user)
      @tracks = client.search_tracks(@query, limit: 25)
    end
  rescue => e
    Rails.logger.error("[LastfmController#search] #{e.class}: #{e.message}")
    @tracks = []
    flash.now[:alert] = 'Could not search Last.fm.'
  end

  # Optional helper endpoint
  def my_tracks
    unless current_user.lastfm_connected
      return redirect_to root_path, alert: 'Last.fm not connected'
    end

    client = LastfmClient.new(current_user)
    @tracks = client.recent_tracks(limit: 20)
  rescue StandardError => e
    Rails.logger.error("Last.fm API error: #{e.message}")
    @tracks = []
  ensure
    render plain: '' unless performed?
  end
end

