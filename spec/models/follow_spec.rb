require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:follower).class_name('User') }
    it { is_expected.to belong_to(:following).class_name('User') }
  end

  describe 'validations' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    subject { build(:follow, follower: user1, following: user2) }

    it { is_expected.to validate_presence_of(:follower_id) }
    it { is_expected.to validate_presence_of(:following_id) }
    it { is_expected.to validate_uniqueness_of(:follower_id).scoped_to(:following_id) }

    describe 'cannot_follow_self validation' do
      it 'prevents a user from following themselves' do
        follow = build(:follow, follower: user1, following: user1)
        follow.valid?
        expect(follow.errors[:base]).to include("Users cannot follow themselves")
      end

      it 'allows following a different user' do
        follow = build(:follow, follower: user1, following: user2)
        expect(follow.valid?).to be true
      end
    end

    describe 'uniqueness validation' do
      context 'when follow relationship exists' do
        before do
          create(:follow, follower: user1, following: user2)
        end

        it 'prevents duplicate follow relationships' do
          duplicate_follow = build(:follow, follower: user1, following: user2)
          duplicate_follow.valid?
          expect(duplicate_follow.errors[:follower_id]).to include('has already been taken')
        end
      end

      context 'when follow relationship does not exist' do
        it 'allows creating a new follow relationship' do
          follow = build(:follow, follower: user1, following: user2)
          expect(follow.valid?).to be true
        end
      end
    end
  end

  describe 'relationships' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:follow) { create(:follow, follower: user1, following: user2) }

    it 'correctly associates follower' do
      expect(follow.follower).to eq(user1)
    end

    it 'correctly associates following' do
      expect(follow.following).to eq(user2)
    end

    it 'creates a follow relationship between two users' do
      expect(follow.persisted?).to be true
      expect(Follow.count).to eq(1)
    end
  end

  describe 'edge cases' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'allows a user to follow multiple users' do
      follow1 = create(:follow, follower: user1, following: user2)
      follow2 = create(:follow, follower: user1, following: user3)
      expect(Follow.where(follower: user1).count).to eq(2)
    end

    it 'allows a user to be followed by multiple users' do
      follow1 = create(:follow, follower: user1, following: user3)
      follow2 = create(:follow, follower: user2, following: user3)
      expect(Follow.where(following: user3).count).to eq(2)
    end

    it 'allows mutual follows between users' do
      follow1 = create(:follow, follower: user1, following: user2)
      follow2 = create(:follow, follower: user2, following: user1)
      expect(Follow.count).to eq(2)
      expect(user1.following).to include(user2)
      expect(user2.following).to include(user1)
    end
  end
end
