Rails.application.routes.draw do
  # Main landing page now shows songs index (moved from albums#index)
  root "songs#index"

  resources :users, only: %i[new show]
  post '/signup_with_lastfm', to: 'users#signup_with_lastfm', as: :signup_with_lastfm
  resource  :session, only: %i[new create destroy]
  resources :friends, only: %i[index show] do
    member do
      post :follow
      delete :unfollow
      get :followers
      get :following
    end
  end
  resources :albums, only: %i[index show new create] do
    resources :reviews, only: %i[create]
  end
  # top-level review routes for creating reviews not tied to an existing album yet
  resources :reviews, only: %i[new create edit update index]

  resources :songs, only: %i[index show]

  resources :playlists do
    member do
      post :publish_to_lastfm
      post :add_lastfm_track
      delete 'remove_song/:song_id', to: 'playlists#remove_song', as: :remove_song
    end
    collection do
      get :from_top_rated
    end
  end

  # Last.fm authentication
  get '/auth/lastfm', to: 'lastfm_auth#auth', as: :lastfm_auth
  get '/auth/lastfm/callback', to: 'lastfm_auth#callback', as: :lastfm_auth_callback
  delete '/disconnect_lastfm', to: 'lastfm_auth#disconnect', as: :disconnect_lastfm
  # Last.fm recent tracks
  get '/lastfm/recent', to: 'lastfm#recent', as: :lastfm_recent
  # Optional helper endpoint used by tests and the UI to list the user's recent tracks
  get '/lastfm/my_tracks', to: 'lastfm#my_tracks', as: :lastfm_my_tracks
  # Server endpoint that returns the session key for the logged-in user
  get '/lastfm/token', to: 'lastfm_auth#token', as: :lastfm_token
  # Search Last.fm tracks (q param)
  get '/lastfm/search', to: 'lastfm#search', as: :lastfm_search
end



