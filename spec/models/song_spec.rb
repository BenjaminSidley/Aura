require 'rails_helper'

RSpec.describe Song, type: :model do
  describe '#average_rating' do
    let(:user1) { User.create!(email: 'u1@example.com', name: 'User1', username: 'u1', password: 'password') }
    let(:user2) { User.create!(email: 'u2@example.com', name: 'User2', username: 'u2', password: 'password') }
    let(:user3) { User.create!(email: 'u3@example.com', name: 'User3', username: 'u3', password: 'password') }

    it 'returns nil when there are no reviews' do
      song = Song.create!(title: 'No Reviews', artist: 'Nobody')
      expect(song.average_rating).to be_nil
    end

    it 'returns the average rating rounded to 2 decimals' do
      song = Song.create!(title: 'Hit', artist: 'Artist')
      song.reviews.create!(user: user1, rating: 5, comment: 'Great track!' * 2)
      song.reviews.create!(user: user2, rating: 3, comment: 'Not bad, could be better' )

      # average = (5 + 3) / 2.0 = 4.0
      expect(song.average_rating).to eq 4.0

      # add another review to make non-integer average
      song.reviews.create!(user: user3, rating: 4, comment: 'Pretty good song' )
      # new average = (5 + 3 + 4) / 3 = 4.0 still
      expect(song.average_rating).to eq 4.0
    end
  end
end
require 'rails_helper'

RSpec.describe Song, type: :model do
  it 'is valid with title and artist' do
    s = Song.new(title: 'Yellow', artist: 'Coldplay')
    expect(s).to be_valid
  end

  it 'is invalid without a title' do
    s = Song.new(artist: 'Coldplay')
    expect(s).not_to be_valid
  end

  it 'is invalid without an artist' do
    s = Song.new(title: 'Yellow')
    expect(s).not_to be_valid
  end

  describe '#average_rating' do
    it 'returns nil when no reviews' do
      song = Song.create!(title: 'No Reviews', artist: 'Nobody')
      expect(song.average_rating).to be_nil
    end

    it 'calculates average rating rounded to 2 decimals' do
      song = Song.create!(title: 'Avg Song', artist: 'Band')
      user1 = create(:user)
      user2 = create(:user)
      create(:review, song: song, rating: 5, user: user1, comment: 'Excellent track')
      create(:review, song: song, rating: 4, user: user2, comment: 'Pretty good')
      expect(song.average_rating).to eq(4.5)
    end
  end
end
