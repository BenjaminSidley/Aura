require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  render_views

  describe 'POST #signup_with_lastfm' do
    context 'with valid params' do
      it 'stores signup data in session and redirects to lastfm auth' do
        expect {
          post :signup_with_lastfm, params: { user: { name: 'Test', username: 'test2', email: 'test@example.com', password: 'password', password_confirmation: 'password' } }
        }.not_to change(User, :count)

        expect(session[:pending_signup]).to be_present
        expect(session[:pending_signup]['email']).to eq('test@example.com')
        expect(response).to redirect_to('/auth/lastfm?signup_flow=true')
      end
    end

    context 'with invalid params' do
      it 'renders new with validation errors' do
        post :signup_with_lastfm, params: { user: { name: '', username: '', email: 'bad', password: 'short', password_confirmation: 'short' } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(session[:pending_signup]).to be_nil
      end
    end
  end
end
