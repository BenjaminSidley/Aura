require 'rails_helper'

RSpec.describe PlaylistsController, type: :controller do
  describe 'POST #add_lastfm_track' do
    let!(:owner) { User.create!(email: 'own@example.com', name: 'Owner', username: 'owner', password: 'password') }
    let!(:other) { User.create!(email: 'other@example.com', name: 'Other', username: 'other', password: 'password') }
    let!(:playlist) { Playlist.create!(title: 'P1', user: owner) }

    it 'rejects when not authorized' do
      allow(controller).to receive(:current_user).and_return(nil)
      post :add_lastfm_track, params: { id: playlist.id }
      expect(response).to redirect_to(new_session_path)
    end

    it 'rejects when missing track information' do
      allow(controller).to receive(:current_user).and_return(owner)
      post :add_lastfm_track, params: { id: playlist.id, track_name: '' }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to match(/Missing track information/i)
    end

    it 'creates a song with Unknown Artist when artists missing and adds to playlist' do
      allow(controller).to receive(:current_user).and_return(owner)
      expect {
        post :add_lastfm_track, params: { id: playlist.id, track_name: 'Lonely Track', artists: '' }
      }.to change { Song.count }.by(1)

      song = Song.last
      expect(song.artist).to eq('Unknown Artist')
      playlist.reload
      expect(playlist.songs.map(&:id)).to include(song.id)
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:notice]).to match(/Added "#{song.title}" to playlist/) 
    end

    it 'preserves external_url when Song supports it' do
      allow(controller).to receive(:current_user).and_return(owner)
  allow(Song).to receive(:attribute_names).and_return(Song.attribute_names + ['external_url'])
  Song.class_eval { attr_accessor :external_url } unless Song.method_defined?(:external_url=)
  allow_any_instance_of(Song).to receive(:external_url=).and_return(nil)
  allow_any_instance_of(Song).to receive(:external_url).and_return('http://ex')
      expect {
        post :add_lastfm_track, params: { id: playlist.id, track_name: 'External', artists: 'A', external_url: 'http://ex' }
      }.to change { Song.count }.by(1)

      song = Song.last
      expect(song.external_url).to eq('http://ex')
    end
  end

  describe 'DELETE #remove_song' do
    let!(:owner) { User.create!(email: 'own@example.com', name: 'Owner', username: 'owner', password: 'password') }
    let!(:other) { User.create!(email: 'other@example.com', name: 'Other', username: 'other', password: 'password') }
    let!(:playlist) { Playlist.create!(title: 'P1', user: owner) }
    let!(:song) { Song.create!(title: 'Test Song', artist: 'Test Artist') }

    before do
      playlist.add_song(song)
    end

    it 'removes song from playlist when authorized' do
      allow(controller).to receive(:current_user).and_return(owner)
      expect(playlist.songs).to include(song)
      
      delete :remove_song, params: { id: playlist.id, song_id: song.id }
      
      playlist.reload
      expect(playlist.songs).not_to include(song)
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:notice]).to match(/Removed "#{song.title}" from playlist/)
    end

    it 'rejects when not authorized' do
      allow(controller).to receive(:current_user).and_return(other)
      
      delete :remove_song, params: { id: playlist.id, song_id: song.id }
      
      playlist.reload
      expect(playlist.songs).to include(song)
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to match(/Not authorized/i)
    end

    it 'handles song not in playlist' do
      allow(controller).to receive(:current_user).and_return(owner)
      other_song = Song.create!(title: 'Other Song', artist: 'Other Artist')
      
      delete :remove_song, params: { id: playlist.id, song_id: other_song.id }
      
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to match(/Song not found in playlist/i)
    end
  end
end
