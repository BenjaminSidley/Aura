require 'rails_helper'

RSpec.describe AnalyticsService, type: :service do
  describe '#lastfm_top_artists and #lastfm_top_tracks' do
    let(:user) { User.create!(email: 'u@example.com', name: 'U', username: 'u', password: 'password') }

    it 'returns empty arrays when user not connected to lastfm' do
      svc = AnalyticsService.new(user)
      expect(svc.lastfm_top_artists).to eq([])
      expect(svc.lastfm_top_tracks).to eq([])
    end

    it 'computes top artists and tracks when lastfm_connected' do
      user.update!(lastfm_connected: true)
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Song A', artists: 'Artist 1' },
        { name: 'Song B', artists: 'Artist 1' },
        { name: 'Song A', artists: 'Artist 1' }
      ])

      svc = AnalyticsService.new(user)
      top_artists = svc.lastfm_top_artists(limit: 2)
      expect(top_artists.first[:artist]).to eq('Artist 1')
      top_tracks = svc.lastfm_top_tracks(limit: 2)
      expect(top_tracks.map { |t| t[:track] }).to include('Song A')
    end
  end

  describe '#aura_top_rated_songs and recommendations_for_user' do
    before do
      @s1 = Song.create!(title: 'Top 1', artist: 'A')
      @s2 = Song.create!(title: 'Top 2', artist: 'B')
  Review.create!(song: @s1, rating: 5, comment: 'Great record', user: User.create!(email: 'r1@example.com', name: 'R1', username: 'r1', password: 'password'))
  Review.create!(song: @s2, rating: 3, comment: 'Not bad at all', user: User.create!(email: 'r2@example.com', name: 'R2', username: 'r2', password: 'password'))
      Rails.cache.clear
    end

    it 'returns aura top rated songs ordered by avg rating' do
      svc = AnalyticsService.new(nil)
      list = svc.aura_top_rated_songs(limit: 2)
      expect(list.first.title).to eq(@s1.title)
    end

    it 'falls back to most_recently_reviewed_songs when user has no reviews and not connected' do
      user = User.create!(email: 'u2@example.com', name: 'U2', username: 'u2', password: 'password')
      svc = AnalyticsService.new(user)
      recs = svc.recommendations_for_user(limit: 2)
      expect(recs).to be_an(Array)
      expect(recs.map(&:class).first).to be(Song)
    end

    it 'maps similar lastfm entries back to local Song records when possible' do
      user = User.create!(email: 'u3@example.com', name: 'U3', username: 'u3', password: 'password')
  reviewed = Song.create!(title: 'Reviewed', artist: 'RArtist')
  Review.create!(song: reviewed, rating: 5, comment: 'A lovely track', user: user)

      local_match = Song.create!(title: 'Other Song', artist: 'OArtist')

      allow_any_instance_of(LastfmClient).to receive(:track_similar).and_return([
        { name: 'Other Song', artist: 'OArtist', url: 'http://x' }
      ])

      svc = AnalyticsService.new(user)
      recs = svc.recommendations_for_user(limit: 5)
      expect(recs.any? { |r| r.is_a?(Song) && r.id == local_match.id }).to be(true)
    end

    it 'returns lightweight lastfm entries when no local match exists using recent tracks' do
      user = User.create!(email: 'u4@example.com', name: 'U4', username: 'u4', password: 'password')
      user.update!(lastfm_connected: true)

      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Recent', artists: 'RA' }
      ])
      allow_any_instance_of(LastfmClient).to receive(:track_similar).and_return([
        { name: 'X', artist: 'Y', url: 'http://x' }
      ])

      svc = AnalyticsService.new(user)
      recs = svc.recommendations_for_user(limit: 3)
      expect(recs.any? { |r| r.is_a?(Hash) && r[:source] == 'lastfm' && r[:name] == 'X' }).to be(true)
    end

    it 'recommendations_for_song defers to recommendations_for_user when recs blank and user provided' do
      user = User.create!(email: 'u5@example.com', name: 'U5', username: 'u5', password: 'password')
      song = Song.create!(title: 'Solo', artist: 'SoloArtist')

  fake = double(recommendations_for_user: [{ name: 'Fallback', artist: 'F', source: 'lastfm' }])
  allow(AnalyticsService).to receive(:new).and_call_original
  allow(AnalyticsService).to receive(:new).with(user).and_return(fake)

  svc = AnalyticsService.new(nil)
  res = svc.recommendations_for_song(song, user, limit: 1)
      expect(res.first[:name]).to eq('Fallback')
    end
  end
end
require 'rails_helper'

RSpec.describe AnalyticsService, type: :service do
  describe '#recommendations_for_user' do
    let(:user) { create(:user) }

    before do
      user.update!(lastfm_connected: true)
      allow_any_instance_of(LastfmClient).to receive(:track_similar).and_return([
        { name: 'Paranoid Android', artist: 'Radiohead', url: 'http://last.fm/p1' },
        { name: 'Unknown Track', artist: 'Some Artist', url: 'http://last.fm/p2' }
      ])

      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil }
      ])
    end

    it 'returns Last.fm entries when no local match exists' do
      service = AnalyticsService.new(user)
      recs = service.recommendations_for_user(limit: 5)

      expect(recs).to be_an(Array)
      expect(recs.first).to be_a(Hash)
      expect(recs.first[:name]).to eq('Paranoid Android')
      expect(recs.first[:artist]).to eq('Radiohead')
    end

    it 'maps to local songs when available' do
      song = create(:song, title: 'Paranoid Android', artist: 'Radiohead')

      service = AnalyticsService.new(user)
      recs = service.recommendations_for_user(limit: 5)

      expect(recs.any? { |r| r.is_a?(Song) && r.id == song.id }).to be true
    end
  end

  describe '#lastfm_top_artists and #lastfm_top_tracks' do
    let(:user) { create(:user) }

    before do
      user.update!(lastfm_connected: true)
    end

    it 'returns top artists with play counts' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
        { name: 'Paranoid Android', artists: 'Radiohead', album: '', image: nil },
        { name: 'Come Together', artists: 'The Beatles', album: '', image: nil }
      ])

      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 2, lookback: 50)

      expect(artists).to be_an(Array)
      expect(artists.first[:artist]).to eq('Radiohead')
      expect(artists.first[:plays]).to eq(2)
      expect(artists.map { |a| a[:artist] }).to include('The Beatles')
    end

    it 'returns top tracks with play counts' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
        { name: 'Karma Police', artists: 'Radiohead', album: '', image: nil },
        { name: 'Hey Jude', artists: 'The Beatles', album: '', image: nil }
      ])

      service = AnalyticsService.new(user)
      tracks = service.lastfm_top_tracks(limit: 3, lookback: 50)

      expect(tracks).to be_an(Array)
      expect(tracks.first[:track]).to eq('Karma Police')
      expect(tracks.first[:plays]).to eq(2)
      expect(tracks.map { |t| t[:artist] }).to include('The Beatles')
    end
  end

  describe '#user_top_rated_songs' do
    let(:user) { create(:user) }

    before do
      @song1 = create(:song, title: 'Song A', artist: 'Artist A')
      @song2 = create(:song, title: 'Song B', artist: 'Artist B')
      @song3 = create(:song, title: 'Song C', artist: 'Artist C')
    end

    it 'returns user top rated songs ordered by rating' do
      create(:review, user: user, song: @song1, rating: 5, comment: 'Excellent!!!')
      create(:review, user: user, song: @song2, rating: 4, comment: 'Very Good!')
      create(:review, user: user, song: @song3, rating: 3, comment: 'Okay Here!')

      service = AnalyticsService.new(user)
      top_songs = service.user_top_rated_songs(limit: 10).to_a

      expect(top_songs).to be_an(Array)
      expect(top_songs.length).to eq(3)
      # Should be ordered by average rating descending
      expect(top_songs.first.id).to eq(@song1.id)
    end

    it 'returns empty array when user has no reviews' do
      service = AnalyticsService.new(user)
      top_songs = service.user_top_rated_songs(limit: 10).to_a

      expect(top_songs).to be_an(Array)
      expect(top_songs).to be_empty
    end

    it 'respects limit parameter' do
      create(:review, user: user, song: @song1, rating: 5, comment: 'Test review')
      create(:review, user: user, song: @song2, rating: 4, comment: 'Test song 2')
      create(:review, user: user, song: @song3, rating: 3, comment: 'Test song 3')

      service = AnalyticsService.new(user)
      top_songs = service.user_top_rated_songs(limit: 2).to_a

      expect(top_songs.length).to eq(2)
    end

    it 'returns empty array when user is nil' do
      service = AnalyticsService.new(nil)
      top_songs = service.user_top_rated_songs(limit: 10)

      expect(top_songs).to be_an(Array)
      expect(top_songs).to be_empty
    end
  end

  describe '#aura_top_rated_songs' do
    before do
      @song1 = create(:song, title: 'Popular 1', artist: 'Artist')
      @song2 = create(:song, title: 'Popular 2', artist: 'Artist')
      @user1 = create(:user)
      @user2 = create(:user)

      create(:review, user: @user1, song: @song1, rating: 5, comment: 'Excellent!!!')
      create(:review, user: @user1, song: @song2, rating: 4, comment: 'Very Good!')
      create(:review, user: @user2, song: @song1, rating: 5, comment: 'Awesome Here!')
      create(:review, user: @user2, song: @song2, rating: 3, comment: 'Decent Sure!')
    end

    it 'returns top rated songs across all users' do
      service = AnalyticsService.new
      top_songs = service.aura_top_rated_songs(limit: 10)

      expect(top_songs).to be_an(Array)
      expect(top_songs.length).to be > 0
      # Song1 has average of 5.0, Song2 has average of 3.5
      expect(top_songs.first.id).to eq(@song1.id)
    end

    it 'respects limit parameter' do
      service = AnalyticsService.new
      top_songs = service.aura_top_rated_songs(limit: 1)

      expect(top_songs.length).to eq(1)
    end

    it 'caches results' do
      service = AnalyticsService.new
      first_call = service.aura_top_rated_songs(limit: 10)

      # Modify data with a new user to avoid duplicate review validation
      new_user = create(:user)
      create(:review, user: new_user, song: @song2, rating: 5, comment: 'Changed Now!')

      second_call = service.aura_top_rated_songs(limit: 10)

      # Should return cached result (same as first call)
      expect(first_call.map(&:id)).to eq(second_call.map(&:id))
    end

    it 'returns empty array when no reviews exist' do
      Review.delete_all
      service = AnalyticsService.new
      top_songs = service.aura_top_rated_songs(limit: 10)

      expect(top_songs).to be_an(Array)
      expect(top_songs).to be_empty
    end
  end

  describe '#lastfm_top_artists with no connection' do
    let(:user) { create(:user) }

    it 'returns empty array when user not Last.fm connected' do
      user.update!(lastfm_connected: false)
      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists).to be_empty
    end

    it 'returns empty array when user is nil' do
      service = AnalyticsService.new(nil)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists).to be_empty
    end
  end

  describe '#lastfm_top_tracks with no connection' do
    let(:user) { create(:user) }

    it 'returns empty array when user not Last.fm connected' do
      user.update!(lastfm_connected: false)
      service = AnalyticsService.new(user)
      tracks = service.lastfm_top_tracks(limit: 5)

      expect(tracks).to be_an(Array)
      expect(tracks).to be_empty
    end

    it 'returns empty array when user is nil' do
      service = AnalyticsService.new(nil)
      tracks = service.lastfm_top_tracks(limit: 5)

      expect(tracks).to be_an(Array)
      expect(tracks).to be_empty
    end
  end

  describe '#lastfm_top_artists with missing artists' do
    let(:user) { create(:user) }

    before do
      user.update!(lastfm_connected: true)
    end

    it 'handles tracks with missing artist names' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([
        { name: 'Song 1', artists: '', album: '', image: nil },
        { name: 'Song 2', artists: 'Artist B', album: '', image: nil }
      ])

      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists.length).to eq(1)
      expect(artists.first[:artist]).to eq('Artist B')
    end

    it 'handles empty recent tracks response' do
      allow_any_instance_of(LastfmClient).to receive(:recent_tracks).and_return([])

      service = AnalyticsService.new(user)
      artists = service.lastfm_top_artists(limit: 5)

      expect(artists).to be_an(Array)
      expect(artists).to be_empty
    end
  end
end
