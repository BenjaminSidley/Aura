class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:signup_with_lastfm]
  
  def new
    @user = User.new
  end

  def signup_with_lastfm
    # Validate user params first
    @user = User.new(user_params)
    
    if @user.valid?
      # Store signup data in session temporarily (use string keys for session compatibility)
      session[:pending_signup] = {
        'name' => params[:user][:name],
        'email' => params[:user][:email],
        'username' => params[:user][:username],
        'password' => params[:user][:password],
        'password_confirmation' => params[:user][:password_confirmation]
      }
      
      # Redirect to Last.fm OAuth with signup flag
      redirect_to lastfm_auth_path(signup_flow: true), allow_other_host: false
    else
      # Show validation errors
      render :new, status: :unprocessable_content
    end
  end

  def show
    @user = User.find(params[:id])
    @analytics = AnalyticsService.new(@user)
    
    # Fetch images for reviews if Last.fm is available
    @review_images = {}
    if ENV['LASTFM_API_KEY'] && @user.reviews.any?
      client = LastfmClient.new(current_user)
      @user.reviews.includes(:song).each do |review|
        next unless review.song.artist.present? && review.song.title.present?
        image = client.get_track_image(review.song.artist, review.song.title)
        @review_images[review.id] = image if image.present?
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :username, :password, :password_confirmation)
  end
end
