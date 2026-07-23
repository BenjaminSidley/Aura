require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  render_views
  let(:user) { create(:user, username: 'testuser', email: 'test@example.com', password: 'password123') }

  describe 'GET #new' do
    it 'renders the login form' do
      get :new
      expect(response).to have_http_status(:ok)
      # assert_template was extracted to a gem; assert the body contains expected text instead
      expect(response.body).to include('Sign in')
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'sets the session and redirects to root' do
        post :create, params: { login: user.username, password: 'password123' }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid credentials' do
      it 'renders new with unprocessable_content' do
        post :create, params: { login: user.username, password: 'wrong' }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Invalid login or password')
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      post :create, params: { login: user.username, password: 'password123' }
      expect(session[:user_id]).to eq(user.id)
    end

    it 'clears the session and redirects' do
      delete :destroy
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
