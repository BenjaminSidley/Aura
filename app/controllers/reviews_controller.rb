class ReviewsController < ApplicationController
  
  before_action :require_login, only: [:create, :edit, :update]
  before_action :set_review, only: [:edit, :update]
  before_action :authorize_user, only: [:edit, :update]

  def index
    @reviews = Review.includes(:song, :user).order(created_at: :desc).limit(50)
  end

  def new
    @review = Review.new
    
    if params[:track_name].present?
      artist_name = params[:artists].presence || params[:artist].presence || 'Unknown Artist'
      @song = Song.find_or_initialize_by(title: params[:track_name].to_s.strip, artist: artist_name) 
      @song.album = params[:album_title] if params[:album_title].present?
    elsif params[:song_id].present?
      @song = Song.find_by(id: params[:song_id])
    end
    
    # Fetch song image from Last.fm if available
    if @song.present? && @song.artist.present? && @song.title.present?
      @song_image = fetch_song_image(@song)
    end
  end

  def create
    # Find or create a Song record and attach the review to it
    if params[:song_id].present?
      song = Song.find(params[:song_id])
    else
      title = params[:track_name]&.strip || params[:title]&.strip
      artist = params[:artists]&.strip
      album_title = params[:album_title]&.strip

      song = if title.present? && artist.present?
               Song.find_or_create_by(title: title, artist: artist) do |s|
                 s.album = album_title
               end
             else
               Song.find_or_create_by(title: title.presence || 'Unknown Track',
                                      artist: artist.presence || 'Unknown Artist')
             end
    end

    review = song.reviews.build(review_params)

    review.rating = review.rating.to_i if review.rating.present?

    review.user = current_user

    if review.save
      # Redirect to the song show page (create a songs#show view)
      redirect_to song_path(song), notice: 'Review added'
    else
      flash.now[:alert] = "Unable to save review: #{review.errors.full_messages.join(', ')}"
      @song = song
      @review = review
      @song_image = fetch_song_image(@song) if @song.artist.present? && @song.title.present?
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @song = @review.song
    @song_image = fetch_song_image(@song) if @song.artist.present? && @song.title.present?
  end

  def update
    @song = @review.song
    
    if @review.update(review_params)
      redirect_to song_path(@song), notice: 'Review updated successfully'
    else
      flash.now[:alert] = "Unable to update review: #{@review.errors.full_messages.join(', ')}"
      @song_image = fetch_song_image(@song) if @song.artist.present? && @song.title.present?
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def authorize_user
    unless @review.user == current_user
      redirect_to root_path, alert: 'You are not authorized to edit this review'
    end
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
  
  def fetch_song_image(song)
    return nil unless ENV['LASTFM_API_KEY']
    
    client = LastfmClient.new(current_user)
    client.get_track_image(song.artist, song.title)
  rescue StandardError => e
    Rails.logger.debug("[ReviewsController#fetch_song_image] Failed: #{e.message}")
    nil
  end
end
