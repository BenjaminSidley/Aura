require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:song) }
  end

  describe 'validations' do
    it { should validate_presence_of(:rating) }
    it { should validate_presence_of(:comment) }
    it { should validate_inclusion_of(:rating).in_range(1..5) }
    it { should validate_length_of(:comment).is_at_least(10) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      user = create(:user)
      song = create(:song)
      review = build(:review, user: user, song: song, rating: 4, comment: 'This is a great song with amazing performance!')
      expect(review).to be_valid
    end
  end

  describe 'rating validation' do
    let(:user) { create(:user) }
    let(:song) { create(:song) }

    it 'is valid with rating between 1 and 5' do
      [1, 2, 3, 4, 5].each do |rating|
        review = build(:review, user: user, song: song, rating: rating, comment: 'This is a valid comment.')
        expect(review).to be_valid
      end
    end

    it 'is invalid with rating less than 1' do
      review = build(:review, user: user, song: song, rating: 0, comment: 'This is a valid comment.')
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include('is not included in the list')
    end

    it 'is invalid with rating greater than 5' do
      review = build(:review, user: user, song: song, rating: 6, comment: 'This is a valid comment.')
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include('is not included in the list')
    end

    it 'is invalid without a rating' do
      review = build(:review, user: user, song: song, rating: nil, comment: 'This is a valid comment.')
      expect(review).not_to be_valid
      expect(review.errors[:rating]).to include("can't be blank")
    end
  end

  describe 'comment validation' do
    let(:user) { create(:user) }
    let(:song) { create(:song) }

    it 'is invalid without a comment' do
      review = build(:review, user: user, song: song, rating: 4, comment: nil)
      expect(review).not_to be_valid
      expect(review.errors[:comment]).to include("can't be blank")
    end

    it 'is invalid with comment shorter than 10 characters' do
      review = build(:review, user: user, song: song, rating: 4, comment: 'Short')
      expect(review).not_to be_valid
      expect(review.errors[:comment]).to include('is too short (minimum is 10 characters)')
    end

    it 'is valid with comment of exactly 10 characters' do
      review = build(:review, user: user, song: song, rating: 4, comment: 'Ten chars!')
      expect(review).to be_valid
    end

    it 'is valid with comment longer than 10 characters' do
      review = build(:review, user: user, song: song, rating: 4, comment: 'This is a longer comment with more details.')
      expect(review).to be_valid
    end
  end

  describe 'creating a review' do
    it 'can be created with valid attributes' do
      user = create(:user)
      song = create(:song)
      
      expect {
        create(:review, user: user, song: song, rating: 5, comment: 'Absolutely fantastic song!')
      }.to change { Review.count }.by(1)
    end
  end
end
