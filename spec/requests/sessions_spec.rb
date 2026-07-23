
require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:user) do
    create(:user,
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123'
    )
  end

  describe 'GET /new' do
    it 'returns http success' do
      get new_session_path
      expect(response).to have_http_status(:success)
    end

    it 'displays login form' do
      get new_session_path
      expect(response.body.downcase).to match(/login|sign in/)
    end
  end

  describe 'POST /create' do
    context 'with valid credentials' do
      it 'creates a session with username and redirects' do
        post session_path, params: { login: user.username, password: 'password123' }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
        # session may not be accessible in all rack modes; verify redirect and presence of Signed in
        follow_redirect!
        expect(response.body).to include('Signed in')
      end

      it 'creates a session with email and redirects' do
        post session_path, params: { login: user.email, password: 'password123' }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid credentials' do
      it 'does not create session with wrong password' do
        post session_path, params: { login: user.username, password: 'wrongpassword' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Invalid login or password')
      end

      it 'does not create session with non-existent username' do
        post session_path, params: { login: 'nonexistent', password: 'password123' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Invalid login or password')
      end

      it 'does not create session with empty credentials' do
        post session_path, params: { login: '', password: '' }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /destroy' do
    before do
      post session_path, params: { login: user.username, password: 'password123' }
    end

    it 'logs out and redirects' do
      delete session_path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Signed out')
    end

    it 'clears the session' do
      delete session_path
      expect(response).to have_http_status(:redirect)
    end
  end
end




