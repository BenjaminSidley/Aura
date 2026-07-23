require 'rails_helper'

RSpec.describe AnalyticsService, type: :service do
  describe 'private batch find helpers' do
    let(:svc) { AnalyticsService.new(nil) }

    it 'returns empty for blank similar_tracks or non-positive limit' do
      expect(svc.send(:batch_find_songs_from_similar, [], [], 5)).to eq([])
      expect(svc.send(:batch_find_songs_from_similar, [{ name: 'x' }], [], 0)).to eq([])
      expect(svc.send(:batch_find_songs_map, [])).to eq({})
    end

    it 'falls back to loose LIKE clauses when exact match returns nothing' do
      s = Song.create!(title: 'The Great Song (Remix)', artist: 'Artist Name')

      similar = [{ name: 'great song', artist: 'artist name' }]
      res = svc.send(:batch_find_songs_from_similar, similar, [], 5)
      expect(res.map(&:id)).to include(s.id)
    end

    it 'builds a map from similar tracks' do
      s = Song.create!(title: 'Map Song', artist: 'Mapper')
      similar = [{ name: 'Map Song', artist: 'Mapper' }]
      map = svc.send(:batch_find_songs_map, similar, [])
      key = ['map song', 'mapper']
      expect(map[key]).to be_a(Song)
      expect(map[key].id).to eq(s.id)
    end
  end
end
