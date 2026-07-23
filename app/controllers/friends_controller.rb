class FriendsController < ApplicationController
  before_action :require_login
  before_action :set_user, only: [:show]

  def index
    @query = params[:q]&.strip
    @friends = if @query.present?
                 User.where.not(id: current_user.id)
                     .where("username ILIKE ? OR name ILIKE ?", "%#{@query}%", "%#{@query}%")
                     .limit(50)
               else
                 User.where.not(id: current_user.id).limit(50)
               end
  end

  def show
    @user = User.find(params[:id])
    @reviews = @user.reviews.order(created_at: :desc)
  end

  def followers
    @user = User.find(params[:id])
    @followers = @user.followers.order(:name)
  end

  def following
    @user = User.find(params[:id])
    @following = @user.following.order(:name)
  end

  def follow
    @user = User.find(params[:id])
    current_user.follow(@user)
    
    respond_to do |format|
      format.turbo_stream { render :follow_unfollow }
      format.html { redirect_to friends_path, notice: "Now following #{@user.name}" }
    end
  end

  def unfollow
    @user = User.find(params[:id])
    current_user.unfollow(@user)
    
    respond_to do |format|
      format.turbo_stream { render :follow_unfollow }
      format.html { redirect_to friends_path, notice: "Unfollowed #{@user.name}" }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
