require 'rails_helper'

RSpec.describe ReviewsController, type: :controller do
  render_views

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    context 'with valid params (new song)' do
      it 'creates a song and review and redirects to song' do
        expect {
          post :create, params: { track_name: 'New Song', artists: 'An Artist', review: { rating: 5, comment: 'Great song' } }
        }.to change(Review, :count).by(1)

        review = Review.last
        expect(review.user).to eq(user)
        expect(response).to redirect_to(song_path(review.song))
      end
    end

    context 'with invalid params' do
      it 'renders new review form with unprocessable_content' do
        # Create a song so the controller has a @song to render with errors
        song = create(:song)
        post :create, params: { song_id: song.id, review: { rating: '', comment: '' } }
        expect(response).to have_http_status(:unprocessable_content)
        # Verify no review was created
        expect(Review.count).to eq(0)
      end
    end
  end
end
require "rails_helper"

RSpec.describe ReviewsController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    context "with valid params and existing album" do
      it "creates a review and redirects to the album" do
        song = create(:song)

        post :create, params: { song_id: song.id, review: { rating: 5, comment: "This is a great song!" } }

        expect(response).to redirect_to(song_path(song))
        expect(flash[:notice]).to match(/Review added/i)
        expect(song.reviews.count).to be >= 1
      end
    end

    context "with invalid params" do
        it "renders new review form with unprocessable_content and sets alert" do
          song = create(:song)

          post :create, params: { song_id: song.id, review: { rating: 0, comment: "short" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash[:alert]).to match(/Unable to save review/i)
          # Verify no review was created
          expect(Review.count).to eq(0)
        end
    end
  end
end
