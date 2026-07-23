require 'rails_helper'

RSpec.describe PlaylistsController, type: :controller do
  describe 'POST #publish_to_lastfm' do
    let!(:owner) { User.create!(email: 'own2@example.com', name: 'Owner2', username: 'owner2', password: 'password') }
    let!(:playlist) { Playlist.create!(title: 'Ppub', user: owner) }

    it 'redirects with alert when user not connected to lastfm' do
      allow(controller).to receive(:current_user).and_return(owner)
      owner.update!(lastfm_connected: false)
      post :publish_to_lastfm, params: { id: playlist.id }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to match(/Last\.fm not connected/i)
    end

    it 'updates playlist when LastfmClient.create_playlist succeeds' do
      allow(controller).to receive(:current_user).and_return(owner)
      owner.update!(lastfm_connected: true)

      client_double = double('LastfmClient')
      allow(LastfmClient).to receive(:new).with(owner).and_return(client_double)
      allow(client_double).to receive(:create_playlist).with(playlist.title, playlist.songs).and_return([true, 'ext123'])

      post :publish_to_lastfm, params: { id: playlist.id }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:notice]).to match(/Playlist published to Last\.fm/i)
      playlist.reload
      expect(playlist.published_to_lastfm).to be_truthy
      expect(playlist.lastfm_playlist_id).to eq('ext123')
    end

    it 'redirects with alert when publish fails' do
      allow(controller).to receive(:current_user).and_return(owner)
      owner.update!(lastfm_connected: true)

      client_double = double('LastfmClient')
      allow(LastfmClient).to receive(:new).with(owner).and_return(client_double)
      allow(client_double).to receive(:create_playlist).and_return([false, nil])

      post :publish_to_lastfm, params: { id: playlist.id }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to match(/Failed to publish playlist to Last\.fm/i)
    end
  end
end
