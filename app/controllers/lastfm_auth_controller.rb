class LastfmAuthController < ApplicationController
  before_action :require_login, except: [:auth, :callback]
  skip_before_action :require_login, only: [:auth, :callback], if: :signup_flow?

  def auth
    api_key = ENV['LASTFM_API_KEY']
    # Force HTTPS for production/Heroku deployments
    protocol = Rails.env.production? ? 'https://' : request.protocol
    callback_url = ENV['LASTFM_CALLBACK_URL'] || lastfm_auth_callback_url(host: request.host_with_port, protocol: protocol)

    unless api_key
      redirect_to root_path, alert: 'Last.fm API not configured'
      return
    end

    # Store signup flow flag in session so we know after callback
    if params[:signup_flow].present?
      session[:lastfm_signup_flow] = true
    end

    auth_url = "http://www.last.fm/api/auth/?api_key=#{api_key}&cb=#{CGI.escape(callback_url)}"
    redirect_to auth_url, allow_other_host: true
  end

  def callback
    token = params[:token]

    unless token
      Rails.logger.warn "[LastfmAuth] callback missing token parameter"
      return redirect_to root_path, alert: 'Last.fm auth failed: no token received'
    end

    Rails.logger.info "[LastfmAuth] Received token: #{token[0..10]}..." if token

    session_data = LastfmClient.get_session(token)

    unless session_data
      Rails.logger.warn "[LastfmAuth] failed to get session for token. Check logs for details."
      return redirect_to root_path, alert: 'Last.fm auth failed: could not get session. Check server logs for details.'
    end

    # Handle signup flow - create user with Last.fm connection
    if session[:pending_signup].present?
      signup_data = session[:pending_signup]
      @user = User.new(
        name: signup_data['name'],
        email: signup_data['email'],
        username: signup_data['username'],
        password: signup_data['password'],
        password_confirmation: signup_data['password_confirmation']
      )
      
      if @user.save
        # Connect Last.fm to the new user
        @user.connect_lastfm_from_session(session_data[:session_key], session_data[:username])
        session[:user_id] = @user.id
        session.delete(:pending_signup)
        session.delete(:lastfm_signup_flow)
        return redirect_to root_path, notice: "Welcome, #{@user.name}! Your Last.fm account is connected."
      else
        session.delete(:pending_signup)
        session.delete(:lastfm_signup_flow)
        return redirect_to new_user_path, alert: 'Account creation failed. Please try again.'
      end
    end

    # Normal flow - connect Last.fm to existing user
    unless current_user
      return redirect_to new_session_path, alert: 'Please log in first'
    end

    current_user.connect_lastfm_from_session(session_data[:session_key], session_data[:username])
    session.delete(:lastfm_signup_flow) if session[:lastfm_signup_flow].present?
    redirect_to root_path, notice: 'Last.fm account connected'
  rescue => e
    Rails.logger.error("[LastfmAuth#callback] #{e.class}: #{e.message}")
    Rails.logger.error("[LastfmAuth#callback] Backtrace: #{e.backtrace.first(10).join("\n")}")
    session.delete(:pending_signup) if session[:pending_signup].present?
    redirect_to root_path, alert: 'Last.fm auth failed'
  end

  def disconnect
    current_user.disconnect_lastfm!
    redirect_to root_path, notice: 'Last.fm disconnected'
  end

  def token
    session_key = current_user.lastfm_session_key
    if session_key
      render json: { session_key: session_key }
    else
      render json: { error: 'no_session' }, status: :unauthorized
    end
  end

  def prompt
  end

  private

  def signup_flow?
    session[:pending_signup].present? || session[:lastfm_signup_flow].present? || params[:signup_flow].present?
  end
end

