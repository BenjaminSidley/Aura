class SessionsController < ApplicationController
  def new; end

  def create
    key = params[:login]
    user = User.find_by(username: key) || User.find_by(email: key)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in"
    else
      flash.now[:alert] = "Invalid login or password"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out"
  end
end
