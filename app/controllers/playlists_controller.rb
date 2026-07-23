class PlaylistsController < ApplicationController
  # Only require login for actions that modify or create playlists
  before_action :require_login, only: %i[new create from_top_rated publish_to_lastfm add_lastfm_track remove_song]
  # Only load playlist for actions that actually exist in this controller.
  # Rails 7.1+ raises when a callback lists non-existent actions, so keep this in sync.
  before_action :set_playlist, only: %i[show publish_to_lastfm add_lastfm_track remove_song]

  def index
    if params[:user_id].present?
      user = User.find_by(id: params[:user_id])
      @playlists = user ? user.playlists.order(created_at: :desc) : []
    else
      @playlists = current_user ? current_user.playlists.order(created_at: :desc) : []
    end
  end

  def show
  end

  def new
    @playlist = current_user.playlists.build(title: params[:title])
    if params[:song_id]
      @preselected_song = Song.find_by(id: params[:song_id])
    end
  end

  def create
    @playlist = current_user.playlists.build(playlist_params)
    if @playlist.save
      if params[:song_id].present?
        song = Song.find_by(id: params[:song_id])
        @playlist.add_song(song) if song
      end
      redirect_to @playlist, notice: 'Playlist created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # Build a playlist from the user's top rated songs (server-side helper)
  def from_top_rated
    # Check if user has reviewed at least 5 songs
    review_count = current_user.reviews.count
    if review_count < 5
      redirect_to playlists_path, alert: 'Please review at least 5 songs before creating a top rated playlist.'
      return
    end

    # Check if user already has a "My Top Rated Songs" playlist to prevent duplicates
    existing_playlist = current_user.playlists.find_by(title: "My Top Rated Songs")
    if existing_playlist
      redirect_to existing_playlist, alert: 'You already have a "My Top Rated Songs" playlist. You can edit or delete it if needed.'
      return
    end

    top = AnalyticsService.new(current_user).user_top_rated_songs(limit: 10)
    @playlist = current_user.playlists.create(title: "My Top Rated Songs")
    top.each { |s| @playlist.add_song(s) }
    redirect_to @playlist, notice: 'Playlist created from your top rated songs.'
  end

  # Publish a playlist to Last.fm (best-effort). Uses LastfmClient#create_playlist.
  def publish_to_lastfm
    return redirect_to @playlist, alert: 'Last.fm not connected' unless current_user.lastfm_connected?

    client = LastfmClient.new(current_user)
    success, external_id = client.create_playlist(@playlist.title, @playlist.songs)
    if success
      @playlist.update(published_to_lastfm: true, lastfm_playlist_id: external_id)
      redirect_to @playlist, notice: 'Playlist published to Last.fm.'
    else
      redirect_to @playlist, alert: 'Failed to publish playlist to Last.fm.'
    end
  end

  # POST /playlists/:id/add_lastfm_track
  # Accepts Last.fm metadata from the search results and adds (or finds) a local Song and appends it to the playlist.
  def add_lastfm_track
    # Only playlist owner may add tracks this way
    unless current_user && @playlist.user == current_user
      redirect_to @playlist, alert: 'Not authorized to modify this playlist.' and return
    end

    track_name = params[:track_name] || params[:name]
    artists = params[:artists]
    album_title = params[:album_title] || params[:album]
    external_url = params[:external_url]

    if track_name.blank?
      redirect_to @playlist, alert: 'Missing track information.' and return
    end

    title = track_name.strip
    # Allow missing artist by falling back to a placeholder so users can still add tracks
    artist = artists.to_s.strip.presence || 'Unknown Artist'

    song = Song.find_or_create_by(title: title, artist: artist) do |s|
      s.album = album_title if album_title.present?
      # preserve external_url if provided
      s.external_url = external_url if song_responds_to_external_url?
    end

    @playlist.add_song(song)
    redirect_to @playlist, notice: "Added \"#{song.title}\" to playlist."
  end

  # DELETE /playlists/:id/remove_song/:song_id
  # Remove a song from the playlist
  def remove_song
    # Only playlist owner may remove songs
    unless current_user && @playlist.user == current_user
      redirect_to @playlist, alert: 'Not authorized to modify this playlist.' and return
    end

    song = Song.find_by(id: params[:song_id])
    if song && @playlist.songs.include?(song)
      @playlist.playlist_songs.where(song_id: song.id).destroy_all
      redirect_to @playlist, notice: "Removed \"#{song.title}\" from playlist."
    else
      redirect_to @playlist, alert: 'Song not found in playlist.'
    end
  end

  def song_responds_to_external_url?
    Song.attribute_names.include?('external_url') rescue false
  end

  private

  def set_playlist
    # Allow viewing a playlist by id. Modification actions will still require login and ownership.
    @playlist = Playlist.find(params[:id])
  end

  def playlist_params
    params.require(:playlist).permit(:title, :description)
  end
end
