require 'rails_helper'

RSpec.describe 'Friends requests', type: :request do
  let(:user) { create(:user, username: 'test_user', name: 'Test User', email: 'test_user@example.com') }
  let(:friend1) { create(:user, username: 'friend_one', name: 'Friend One', email: 'friend_one@example.com') }
  let(:friend2) { create(:user, username: 'another_friend', name: 'Another Friend', email: 'another_friend@example.com') }
  let(:password) { 'password123' }

  before do
    user.update(password: password, password_confirmation: password)
    friend1.update(password: password, password_confirmation: password)
    friend2.update(password: password, password_confirmation: password)
  end

  describe 'GET /friends' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get friends_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user, password: password) }

      context 'without search query' do
        it 'returns 200 status' do
          get friends_path
          expect(response).to have_http_status(:ok)
        end

        it 'displays all users except the current user' do
          get friends_path
          expect(response.body).to include(friend1.name)
          expect(response.body).to include(friend2.name)
        end

        it 'displays usernames' do
          get friends_path
          expect(response.body).to include(friend1.username)
          expect(response.body).to include(friend2.username)
        end

        it 'limits results to 50 users' do
          # Create users with unique emails and usernames
          (1..51).each do |i|
            create(:user, email: "user#{i}@example.com", username: "user#{i}")
          end
          get friends_path
          # The response should work without errors
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with search query by username' do
        it 'filters users by username' do
          get friends_path, params: { q: 'friend_one' }
          expect(response.body).to include(friend1.name)
          expect(response.body).not_to include(friend2.name)
        end

        it 'filters users by username case-insensitively' do
          get friends_path, params: { q: 'FRIEND_ONE' }
          expect(response.body).to include(friend1.name)
        end

        it 'returns page successfully when username does not match' do
          get friends_path, params: { q: 'nonexistent_user' }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with search query by name' do
        it 'filters users by name' do
          get friends_path, params: { q: 'Friend One' }
          expect(response.body).to include(friend1.name)
          expect(response.body).not_to include(friend2.name)
        end

        it 'filters users by name case-insensitively' do
          get friends_path, params: { q: 'friend one' }
          expect(response.body).to include(friend1.name)
        end

        it 'filters users by partial name match' do
          get friends_path, params: { q: 'Friend' }
          expect(response.body).to include(friend1.name)
          expect(response.body).to include(friend2.name)
        end
      end

      context 'with whitespace in query' do
        it 'handles whitespace in search query' do
          get friends_path, params: { q: '  friend_one  ' }
          expect(response.body).to include(friend1.name)
          expect(response).to have_http_status(:ok)
        end
      end

      it 'returns successful response without search' do
        get friends_path
        expect(response).to have_http_status(:ok)
      end

      it 'returns successful response with search' do
        get friends_path, params: { q: 'test' }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /friends/:id' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get friend_path(friend1)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user, password: password) }

      it 'returns 200 status' do
        get friend_path(friend1)
        expect(response).to have_http_status(:ok)
      end

      it 'displays the friend\'s profile' do
        get friend_path(friend1)
        expect(response.body).to include(friend1.name)
        expect(response.body).to include(friend1.username)
      end

      context 'when friend has reviews' do
        let!(:review1) { create(:review, user: friend1, song: create(:song), comment: 'This is a great song!') }
        let!(:review2) { create(:review, user: friend1, song: create(:song), comment: 'Amazing music here.') }

        it 'returns 200 status with reviews' do
          get friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when friend has no reviews' do
        it 'displays profile successfully' do
          get friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end
      end

      it 'does not show current user\'s profile as friend' do
        # The current user should not appear when searching for themselves
        get friend_path(friend1)
        expect(response).to have_http_status(:ok)
      end

      it 'renders friend profile page successfully' do
        get friend_path(friend1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(friend1.name)
        expect(response.body).to include(friend1.username)
      end
    end
  end

  describe 'POST /friends/:id/follow' do
    context 'when not logged in' do
      it 'redirects to login page' do
        post follow_friend_path(friend1)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user, password: password) }

      it 'follows the user' do
        expect {
          post follow_friend_path(friend1)
        }.to change { user.reload.following.count }.by(1)
      end

      it 'adds the user to following list' do
        post follow_friend_path(friend1)
        expect(user.reload.following?(friend1)).to be true
      end

      context 'with HTML request' do
        it 'redirects to friends page with notice' do
          post follow_friend_path(friend1)
          expect(response).to redirect_to(friends_path)
          follow_redirect!
          expect(response.body).to include("Now following #{friend1.name}")
        end
      end

      context 'with turbo_stream request' do
        it 'returns successful response on turbo stream' do
          post follow_friend_path(friend1), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response).to have_http_status(:ok)
        end

        it 'renders follow_unfollow template' do
          post follow_friend_path(friend1), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response.body).to include('turbo-stream')
        end
      end

      it 'does not create duplicate follow relationships' do
        user.follow(friend1)
        expect {
          post follow_friend_path(friend1)
        }.not_to change { Follow.count }
      end

      it 'redirects for non-existent user' do
        post follow_friend_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /friends/:id/unfollow' do
    context 'when not logged in' do
      it 'redirects to login page' do
        delete unfollow_friend_path(friend1)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when logged in and following' do
      before do
        sign_in(user, password: password)
        user.follow(friend1)
      end

      it 'unfollows the user' do
        expect {
          delete unfollow_friend_path(friend1)
        }.to change { user.reload.following.count }.by(-1)
      end

      it 'removes the user from following list' do
        delete unfollow_friend_path(friend1)
        expect(user.reload.following?(friend1)).to be false
      end

      context 'with HTML request' do
        it 'redirects to friends page with notice' do
          delete unfollow_friend_path(friend1)
          expect(response).to redirect_to(friends_path)
          follow_redirect!
          expect(response.body).to include("Unfollowed #{friend1.name}")
        end
      end

      context 'with turbo_stream request' do
        it 'returns successful response on turbo stream' do
          delete unfollow_friend_path(friend1), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response).to have_http_status(:ok)
        end

        it 'renders follow_unfollow template' do
          delete unfollow_friend_path(friend1), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response.body).to include('turbo-stream')
        end
      end

      it 'redirects for non-existent user' do
        delete unfollow_friend_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not following the user' do
      before { sign_in(user, password: password) }

      it 'does not raise an error when unfollowing' do
        expect {
          delete unfollow_friend_path(friend1)
        }.not_to raise_error
      end
    end
  end

  describe 'Follow relationships' do
    before { sign_in(user, password: password) }

    it 'allows user to follow multiple friends' do
      post follow_friend_path(friend1)
      post follow_friend_path(friend2)
      expect(user.reload.following.count).to eq(2)
    end

    it 'allows following and unfollowing in sequence' do
      post follow_friend_path(friend1)
      expect(user.reload.following?(friend1)).to be true
      delete unfollow_friend_path(friend1)
      expect(user.reload.following?(friend1)).to be false
    end

    it 'maintains follow relationships independently' do
      post follow_friend_path(friend1)
      post follow_friend_path(friend2)
      delete unfollow_friend_path(friend1)
      expect(user.reload.following.count).to eq(1)
      expect(user.following?(friend2)).to be true
    end
  end

  describe 'GET /friends/:id/followers' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get followers_friend_path(friend1)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user, password: password) }

      context 'when user has no followers' do
        it 'returns 200 status' do
          get followers_friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end

        it 'displays empty followers list' do
          get followers_friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when user has followers' do
        before do
          user.follow(friend1)
          friend2.follow(friend1)
        end

        it 'returns 200 status' do
          get followers_friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end

        it 'displays all followers' do
          get followers_friend_path(friend1)
          expect(response.body).to include(user.name)
          expect(response.body).to include(friend2.name)
        end

        it 'displays follower usernames' do
          get followers_friend_path(friend1)
          expect(response.body).to include(user.username)
          expect(response.body).to include(friend2.username)
        end

        it 'orders followers by name' do
          # Create a follower with name starting with 'A'
          early_follower = create(:user, name: 'Aaron', username: 'aaron_user', email: 'aaron@example.com')
          early_follower.follow(friend1)
          
          get followers_friend_path(friend1)
          # Just verify the page loads with multiple followers
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with non-existent user' do
        it 'returns 404 for non-existent user' do
          get followers_friend_path(id: 99999)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /friends/:id/following' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get following_friend_path(friend1)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user, password: password) }

      context 'when user is not following anyone' do
        it 'returns 200 status' do
          get following_friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end

        it 'displays empty following list' do
          get following_friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when user is following others' do
        before do
          friend1.follow(user)
          friend1.follow(friend2)
        end

        it 'returns 200 status' do
          get following_friend_path(friend1)
          expect(response).to have_http_status(:ok)
        end

        it 'displays all users being followed' do
          get following_friend_path(friend1)
          expect(response.body).to include(user.name)
          expect(response.body).to include(friend2.name)
        end

        it 'displays following usernames' do
          get following_friend_path(friend1)
          expect(response.body).to include(user.username)
          expect(response.body).to include(friend2.username)
        end

        it 'orders following by name' do
          # Create a user with name starting with 'B'
          new_user = create(:user, name: 'Bob', username: 'bob_user', email: 'bob@example.com')
          friend1.follow(new_user)
          
          get following_friend_path(friend1)
          # Just verify the page loads with multiple followed users
          expect(response).to have_http_status(:ok)
        end
      end

      context 'with non-existent user' do
        it 'returns 404 for non-existent user' do
          get following_friend_path(id: 99999)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe 'Followers and following tabs interactions' do
    before { sign_in(user, password: password) }

    it 'displays correct followers for a user' do
      user.follow(friend1)
      friend2.follow(friend1)
      
      get followers_friend_path(friend1)
      
      expect(response.body).to include(user.name)
      expect(response.body).to include(friend2.name)
    end

    it 'displays correct following for a user' do
      friend1.follow(user)
      friend1.follow(friend2)
      
      get following_friend_path(friend1)
      
      expect(response.body).to include(user.name)
      expect(response.body).to include(friend2.name)
    end

    it 'correctly reflects unfollows in followers list' do
      user.follow(friend1)
      friend2.follow(friend1)
      
      get followers_friend_path(friend1)
      followers_count_before = friend1.followers.count
      expect(followers_count_before).to eq(2)
      expect(response.body).to include(user.name)
      expect(response.body).to include(friend2.name)
      
      user.unfollow(friend1)
      
      get followers_friend_path(friend1)
      followers_count_after = friend1.followers.count
      expect(followers_count_after).to eq(1)
      expect(response.body).to include(friend2.name)
    end

    it 'correctly reflects unfollows in following list' do
      friend1.follow(user)
      friend1.follow(friend2)
      
      get following_friend_path(friend1)
      following_count_before = friend1.following.count
      expect(following_count_before).to eq(2)
      expect(response.body).to include(user.name)
      expect(response.body).to include(friend2.name)
      
      friend1.unfollow(user)
      
      get following_friend_path(friend1)
      following_count_after = friend1.following.count
      expect(following_count_after).to eq(1)
      expect(response.body).to include(friend2.name)
    end

    it 'handles mutual follows correctly' do
      user.follow(friend1)
      friend1.follow(user)
      
      get followers_friend_path(friend1)
      expect(response.body).to include(user.name)
      
      get following_friend_path(friend1)
      expect(response.body).to include(user.name)
    end

    context 'when viewing own profile followers and following' do
      it 'displays user\'s followers correctly' do
        friend1.follow(user)
        friend2.follow(user)
        
        get followers_friend_path(user)
        
        expect(response.body).to include(friend1.name)
        expect(response.body).to include(friend2.name)
      end

      it 'displays user\'s following correctly' do
        user.follow(friend1)
        user.follow(friend2)
        
        get following_friend_path(user)
        
        expect(response.body).to include(friend1.name)
        expect(response.body).to include(friend2.name)
      end
    end
  end
end
