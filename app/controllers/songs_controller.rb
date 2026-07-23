class SongsController < ApplicationController
  def show
    @song = Song.find(params[:id])
    @reviews = @song.reviews.order(created_at: :desc)
    @recommendations = AnalyticsService.new(current_user).recommendations_for_song(@song, current_user)
    
    # Fetch song image from Last.fm if available
    @song_image = fetch_song_image(@song) if @song.artist.present? && @song.title.present?
  end
  
  private
  
  def fetch_song_image(song)
    return nil unless ENV['LASTFM_API_KEY']
    
    client = LastfmClient.new(current_user)
    client.get_track_image(song.artist, song.title)
  rescue StandardError => e
    Rails.logger.debug("[SongsController#fetch_song_image] Failed: #{e.message}")
    nil
  end

  def index
    if current_user
      @recommendations = AnalyticsService.new(current_user).recommendations_for_user(limit: 10)
    else
      @recommendations = []
    end
  end
end
