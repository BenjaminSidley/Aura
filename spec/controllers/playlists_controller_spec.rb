require 'rails_helper'

RSpec.describe PlaylistsController, type: :controller do
  let(:user) { create(:user) }
  let(:playlist) { create(:playlist, user: user) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #add_lastfm_track' do
    it 'creates a Song if missing and adds it to the playlist' do
      params = { track_name: 'New Song', artists: 'Some Artist', album_title: 'LP' }
      expect {
        post :add_lastfm_track, params: { id: playlist.id }.merge(params)
      }.to change(Song, :count).by(1)

      expect(playlist.songs.reload.map(&:title)).to include('New Song')
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:notice]).to be_present
    end

    it 'requires ownership to add' do
      other = create(:user, email: 'other@example.com', username: 'other')
      allow(controller).to receive(:current_user).and_return(other)
      post :add_lastfm_track, params: { id: playlist.id, track_name: 'X', artists: 'Y' }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to be_present
    end

    it 'redirects with alert when track_name missing' do
      post :add_lastfm_track, params: { id: playlist.id, artists: 'Artist' }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to be_present
    end

    it 'redirects with alert when artists missing' do
      post :add_lastfm_track, params: { id: playlist.id, track_name: 'Song' }
      expect(response).to redirect_to(playlist_path(playlist))
    end

    it 'reuses existing song if already in database' do
      song = create(:song, title: 'Existing', artist: 'Artist')
      expect {
        post :add_lastfm_track, params: { id: playlist.id, track_name: 'Existing', artists: 'Artist' }
      }.not_to change(Song, :count)

      expect(playlist.songs.reload).to include(song)
    end

    it 'handles song with album information' do
      post :add_lastfm_track, params: { id: playlist.id, track_name: 'Song', artists: 'Artist', album_title: 'Album' }
      song = Song.find_by(title: 'Song', artist: 'Artist')
      expect(song.album).to eq('Album')
    end
  end

  describe 'POST #publish_to_lastfm' do
    it 'redirects with alert when Last.fm not connected' do
      user.update!(lastfm_connected: false)
      post :publish_to_lastfm, params: { id: playlist.id }
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to include('Last.fm not connected')
    end

    it 'publishes playlist when Last.fm connected' do
      user.update!(lastfm_connected: true)
      client = double('client', create_playlist: [true, 'external123'])
      expect(LastfmClient).to receive(:new).with(user).and_return(client)

      post :publish_to_lastfm, params: { id: playlist.id }
      
      playlist.reload
      expect(playlist.published_to_lastfm).to be true
      expect(playlist.lastfm_playlist_id).to eq('external123')
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:notice]).to be_present
    end

    it 'shows error when Last.fm publish fails' do
      user.update!(lastfm_connected: true)
      client = double('client', create_playlist: [false, nil])
      expect(LastfmClient).to receive(:new).with(user).and_return(client)

      post :publish_to_lastfm, params: { id: playlist.id }
      
      expect(response).to redirect_to(playlist_path(playlist))
      expect(flash[:alert]).to include('Failed')
    end
  end

  describe 'GET #from_top_rated' do
    it 'creates playlist from top rated songs when user has 5+ reviews' do
      song1 = create(:song, title: 'Top 1', artist: 'Artist')
      song2 = create(:song, title: 'Top 2', artist: 'Artist')
      song3 = create(:song, title: 'Top 3', artist: 'Artist')
      song4 = create(:song, title: 'Top 4', artist: 'Artist')
      song5 = create(:song, title: 'Top 5', artist: 'Artist')
      
      create(:review, user: user, song: song1, rating: 5, comment: 'Excellent track!')
      create(:review, user: user, song: song2, rating: 4, comment: 'Very good song!')
      create(:review, user: user, song: song3, rating: 4, comment: 'Good music here!')
      create(:review, user: user, song: song4, rating: 3, comment: 'Nice to listen!')
      create(:review, user: user, song: song5, rating: 3, comment: 'Decent overall!')

      expect {
        get :from_top_rated
      }.to change(Playlist, :count).by(1)

      new_playlist = Playlist.last
      expect(new_playlist.title).to eq('My Top Rated Songs')
      expect(new_playlist.user).to eq(user)
      expect(response).to redirect_to(playlist_path(new_playlist))
      expect(flash[:notice]).to be_present
    end

    it 'redirects with alert when user has fewer than 5 reviews' do
      song1 = create(:song, title: 'Top 1', artist: 'Artist')
      song2 = create(:song, title: 'Top 2', artist: 'Artist')
      
      create(:review, user: user, song: song1, rating: 5, comment: 'Excellent track!')
      create(:review, user: user, song: song2, rating: 4, comment: 'Very good song!')

      expect {
        get :from_top_rated
      }.not_to change(Playlist, :count)

      expect(response).to redirect_to(playlists_path)
      expect(flash[:alert]).to eq('Please review at least 5 songs before creating a top rated playlist.')
    end

    it 'redirects with alert when user has no reviews' do
      expect {
        get :from_top_rated
      }.not_to change(Playlist, :count)

      expect(response).to redirect_to(playlists_path)
      expect(flash[:alert]).to eq('Please review at least 5 songs before creating a top rated playlist.')
    end
  end

  describe 'GET #index' do
    it 'returns successful response' do
      playlist
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns successful response' do
      get :show, params: { id: playlist.id }
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'returns successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'preselects song when song_id provided' do
      song = create(:song)
      get :new, params: { song_id: song.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'creates playlist' do
      expect {
        post :create, params: { playlist: { title: 'My Songs' } }
      }.to change(Playlist, :count).by(1)

      expect(response).to redirect_to(Playlist.last)
      expect(flash[:notice]).to include('created')
    end

    it 'adds song to playlist when song_id provided' do
      song = create(:song)
      post :create, params: { playlist: { title: 'New' }, song_id: song.id }
      
      new_playlist = Playlist.last
      expect(new_playlist.songs).to include(song)
    end

    it 'validates title presence' do
      expect {
        post :create, params: { playlist: { title: '' } }
      }.not_to change(Playlist, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end

