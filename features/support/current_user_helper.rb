module CurrentUserHelper
  def current_user
    return @current_user if @current_user
    # Try to find user from session/cookie or instance variable
    email = @current_user_email || 'tester@example.com'
    @current_user ||= User.find_by(email: email)
  end
  
  def set_current_user(user)
    @current_user = user
    @current_user_email = user.email
  end
end

World(CurrentUserHelper)
