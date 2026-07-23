module OmniauthHelpers
  def mock_spotify_auth_hash(uid: 'spotify-123', token: 'access-token', refresh_token: 'refresh-token')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
      provider: 'spotify',
      uid: uid,
      info: { name: 'Spotify User', email: 'sp@example.com' },
      credentials: { token: token, refresh_token: refresh_token, expires_in: 3600 }
    )
    OmniAuth.config.mock_auth[:spotify]
  end

  def clear_mock_auth
    OmniAuth.config.mock_auth[:spotify] = nil
    OmniAuth.config.test_mode = false
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers
end
