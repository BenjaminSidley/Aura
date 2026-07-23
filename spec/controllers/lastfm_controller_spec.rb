require 'rails_helper'

RSpec.describe LastfmController, type: :controller do
  let(:user) { User.create!(email: 'u2@example.com', name: 'U2', username: 'u2', password: 'password') }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #recent' do
    it 'redirects when not connected' do
      user.update!(lastfm_connected: false)
      get :recent
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'assigns tracks when connected' do
      user.update!(lastfm_connected: true)
      client = double('lf', recent_tracks: [{ name: 'T' }])
      expect(LastfmClient).to receive(:new).with(user).and_return(client)
      get :recent
  expect(controller.instance_variable_get(:@tracks)).to be_an(Array)
    end
  end

  describe 'GET #search' do
    it 'returns empty tracks when no query' do
  get :search
  expect(controller.instance_variable_get(:@tracks)).to eq([])
    end

    it 'calls client when query present' do
      user.update!(lastfm_connected: true)
      client = double('lf', search_tracks: [{ name: 'X' }])
      expect(LastfmClient).to receive(:new).with(user).and_return(client)
  get :search, params: { q: 'foo' }
  expect(controller.instance_variable_get(:@tracks)).to be_an(Array)
    end
  end

  describe 'GET #my_tracks' do
    it 'redirects when not connected' do
      user.update!(lastfm_connected: false)
      get :my_tracks
      expect(response).to redirect_to(root_path)
    end

    it 'renders plain when called and connected' do
      user.update!(lastfm_connected: true)
      client = double('lf', recent_tracks: [])
      allow(LastfmClient).to receive(:new).and_return(client)
      get :my_tracks
      expect(response.body).to be_a(String)
    end
  end
end
