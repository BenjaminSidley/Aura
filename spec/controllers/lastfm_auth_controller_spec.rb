require 'rails_helper'

RSpec.describe LastfmAuthController, type: :controller do
  let(:user) { User.create!(email: 'la@example.com', name: 'LA', username: 'la1', password: 'password') }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #auth' do
    it 'redirects to root when api key missing' do
      ENV['LASTFM_API_KEY'] = nil
      get :auth
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects to last.fm when api key present' do
      ENV['LASTFM_API_KEY'] = 'k'
      get :auth
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('last.fm')
    end

    it 'sets signup flow flag when signup_flow param is present' do
      ENV['LASTFM_API_KEY'] = 'k'
      get :auth, params: { signup_flow: true }
      expect(session[:lastfm_signup_flow]).to eq(true)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET #callback' do
    it 'redirects with alert when no token' do
      get :callback
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'redirects with alert when get_session fails' do
      allow(LastfmClient).to receive(:get_session).and_return(nil)
      get :callback, params: { token: 't' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'connects user when get_session succeeds' do
      allow(LastfmClient).to receive(:get_session).and_return({ session_key: 's', username: 'bob' })
      expect_any_instance_of(User).to receive(:connect_lastfm_from_session).with('s', 'bob')
      get :callback, params: { token: 't' }
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to be_present
    end

    context 'with signup flow' do
      before do
        # Don't require login for signup flow
        allow(controller).to receive(:require_login).and_call_original
        allow(controller).to receive(:current_user).and_return(nil)
        
        # Simulate pending signup data in session
        session[:pending_signup] = {
          'name' => 'New User',
          'email' => 'newuser@example.com',
          'username' => 'newuser',
          'password' => 'password123',
          'password_confirmation' => 'password123'
        }
      end

      it 'creates a new user with Last.fm connected on successful callback' do
        allow(LastfmClient).to receive(:get_session).and_return({ session_key: 'session123', username: 'lastfm_user' })
        
        expect {
          get :callback, params: { token: 'token123' }
        }.to change(User, :count).by(1)
        
        new_user = User.last
        expect(new_user.email).to eq('newuser@example.com')
        expect(new_user.lastfm_session_key).to eq('session123')
        expect(new_user.lastfm_username).to eq('lastfm_user')
        expect(session[:user_id]).to eq(new_user.id)
        expect(session[:pending_signup]).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Welcome')
      end

      it 'redirects with alert when Last.fm authentication fails during signup' do
        allow(LastfmClient).to receive(:get_session).and_return(nil)
        
        expect {
          get :callback, params: { token: 'bad_token' }
        }.not_to change(User, :count)
        
        expect(session[:pending_signup]).to be_present
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'POST #disconnect' do
    it 'disconnects the current user and redirects' do
      expect_any_instance_of(User).to receive(:disconnect_lastfm!)
      get :disconnect
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #token' do
    it 'returns unauthorized when no session_key' do
      user.update!(lastfm_session_key: nil)
      get :token
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('no_session')
    end

    it 'returns session_key when present' do
      user.update!(lastfm_session_key: 'abc')
      get :token
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['session_key']).to eq('abc')
    end
  end
end
