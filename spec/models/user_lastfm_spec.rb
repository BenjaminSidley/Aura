require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#connect_lastfm_from_session' do
    it 'sets lastfm fields and clears other users with same username' do
      other = User.create!(email: 'o@example.com', name: 'Other', username: 'other', password: 'pass')
      other.update!(lastfm_username: 'bob', lastfm_session_key: 'old', lastfm_connected: true)

      u = User.create!(email: 'u@example.com', name: 'U', username: 'u1', password: 'pass')

      expect { u.connect_lastfm_from_session('newkey', 'bob') }.not_to raise_error

      u.reload
      other.reload

      expect(u.lastfm_username).to eq('bob')
      expect(u.lastfm_session_key).to eq('newkey')
      expect(u.lastfm_connected).to be true

      expect(other.lastfm_username).to be_nil
      expect(other.lastfm_session_key).to be_nil
      expect(other.lastfm_connected).to be_falsey
    end

    it 'disconnect_lastfm! clears fields' do
      u = User.create!(email: 'x@example.com', name: 'X', username: 'x1', password: 'pass', lastfm_username: 'z', lastfm_session_key: 'k', lastfm_connected: true)
      u.disconnect_lastfm!
      u.reload
      expect(u.lastfm_username).to be_nil
      expect(u.lastfm_session_key).to be_nil
      expect(u.lastfm_connected).to be_falsey
    end
  end
end
