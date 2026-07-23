module RequestHelpers
  # Signs in a user by POSTing to the session create action.
  # This mirrors how the application sets session[:user_id].
  def sign_in(user, password: 'password123')
    post session_path, params: { login: user.username || user.email, password: password }
    follow_redirect! if response.redirect?
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
