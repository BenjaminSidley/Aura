require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#connect_lastfm_from_session' do
    it 'connects user and clears other users with same lastfm_username' do
      other = User.create!(email: 'o@example.com', name: 'O', username: 'o', password: 'password')
      other.update!(lastfm_username: 'bob', lastfm_session_key: 'oldsk', lastfm_connected: true)

      user = User.create!(email: 'u@example.com', name: 'U', username: 'u', password: 'password')

      result = user.connect_lastfm_from_session('newsk', 'bob')
      expect(result).not_to be false
      other.reload
      expect(other.lastfm_username).to be_nil
      expect(other.lastfm_connected).to be_falsey
      user.reload
      expect(user.lastfm_username).to eq('bob')
      expect(user.lastfm_session_key).to eq('newsk')
      expect(user.lastfm_connected).to be_truthy
    end

    it 'returns false and logs when save! raises' do
      user = User.create!(email: 'u2@example.com', name: 'U2', username: 'u2', password: 'password')
      allow(user).to receive(:save!).and_raise(StandardError.new('boom'))
      res = nil
      expect { res = user.connect_lastfm_from_session('sk', 'x') }.not_to raise_error
      expect(res).to eq(false)
    end
  end

  describe '#disconnect_lastfm!' do
    it 'clears lastfm fields' do
      user = User.create!(email: 'd@example.com', name: 'D', username: 'd', password: 'password')
      user.update!(lastfm_username: 'n', lastfm_session_key: 'sk', lastfm_connected: true)
      user.disconnect_lastfm!
      user.reload
      expect(user.lastfm_username).to be_nil
      expect(user.lastfm_session_key).to be_nil
      expect(user.lastfm_connected).to be_falsey
    end
  end
end
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations and associations' do
    subject { build(:user) }

    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to have_secure_password }
  end

  describe 'follow associations' do
    subject { build(:user) }

    it { is_expected.to have_many(:follows_as_follower).dependent(:destroy) }
    it { is_expected.to have_many(:follows_as_following).dependent(:destroy) }
    it { is_expected.to have_many(:following).through(:follows_as_follower).source(:following) }
    it { is_expected.to have_many(:followers).through(:follows_as_following).source(:follower) }
  end

  describe '#follow' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    context 'when user is not already following' do
      it 'adds the user to following list' do
        expect {
          user1.follow(user2)
        }.to change { user1.following.count }.by(1)
      end

      it 'creates a Follow record' do
        expect {
          user1.follow(user2)
        }.to change { Follow.count }.by(1)
      end

      it 'makes the user appear in following collection' do
        user1.follow(user2)
        expect(user1.following).to include(user2)
      end
    end

    context 'when user is already following' do
      before { user1.follow(user2) }

      it 'does not create duplicate follow relationships' do
        expect {
          user1.follow(user2)
        }.not_to change { Follow.count }
      end

      it 'does not change the following count' do
        expect {
          user1.follow(user2)
        }.not_to change { user1.following.count }
      end
    end

    context 'with multiple follows' do
      it 'allows user to follow multiple users' do
        user1.follow(user2)
        user1.follow(user3)
        expect(user1.following.count).to eq(2)
        expect(user1.following).to include(user2, user3)
      end
    end
  end

  describe '#unfollow' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    context 'when user is following' do
      before { user1.follow(user2) }

      it 'removes the user from following list' do
        expect {
          user1.unfollow(user2)
        }.to change { user1.following.count }.by(-1)
      end

      it 'deletes the Follow record' do
        expect {
          user1.unfollow(user2)
        }.to change { Follow.count }.by(-1)
      end

      it 'user is no longer in following collection' do
        user1.unfollow(user2)
        expect(user1.following).not_to include(user2)
      end
    end

    context 'when user is not following' do
      it 'does not raise an error' do
        expect {
          user1.unfollow(user2)
        }.not_to raise_error
      end

      it 'does not change the following count' do
        expect {
          user1.unfollow(user2)
        }.not_to change { user1.following.count }
      end

      it 'does not change Follow count' do
        expect {
          user1.unfollow(user2)
        }.not_to change { Follow.count }
      end
    end

    context 'with multiple follows' do
      before do
        user1.follow(user2)
        user1.follow(user3)
      end

      it 'only removes the specified user' do
        user1.unfollow(user2)
        expect(user1.following).to include(user3)
        expect(user1.following).not_to include(user2)
        expect(user1.following.count).to eq(1)
      end
    end
  end

  describe '#following?' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    context 'when user is following' do
      before { user1.follow(user2) }

      it 'returns true' do
        expect(user1.following?(user2)).to be true
      end
    end

    context 'when user is not following' do
      it 'returns false' do
        expect(user1.following?(user2)).to be false
      end
    end

    context 'with multiple follows' do
      before do
        user1.follow(user2)
        user1.follow(user3)
      end

      it 'returns true for followed user' do
        expect(user1.following?(user2)).to be true
      end

      it 'returns true for another followed user' do
        expect(user1.following?(user3)).to be true
      end

      it 'returns false for unfollowed user' do
        other_user = create(:user)
        expect(user1.following?(other_user)).to be false
      end
    end

    context 'after unfollowing' do
      before do
        user1.follow(user2)
        user1.unfollow(user2)
      end

      it 'returns false' do
        expect(user1.following?(user2)).to be false
      end
    end
  end

  describe 'followers association' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'correctly tracks followers' do
      user2.follow(user1)
      user3.follow(user1)
      expect(user1.followers.count).to eq(2)
      expect(user1.followers).to include(user2, user3)
    end

    it 'does not include unfollowers' do
      user2.follow(user1)
      user3.follow(user1)
      user2.unfollow(user1)
      expect(user1.followers.count).to eq(1)
      expect(user1.followers).not_to include(user2)
      expect(user1.followers).to include(user3)
    end
  end

  describe 'following association' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'correctly tracks following' do
      user1.follow(user2)
      user1.follow(user3)
      expect(user1.following.count).to eq(2)
      expect(user1.following).to include(user2, user3)
    end

    it 'does not include unfollowed users' do
      user1.follow(user2)
      user1.follow(user3)
      user1.unfollow(user2)
      expect(user1.following.count).to eq(1)
      expect(user1.following).not_to include(user2)
      expect(user1.following).to include(user3)
    end
  end
end
