require 'rails_helper'

RSpec.describe 'lastfm/search.html.erb', type: :view do
  it 'renders Add to playlist buttons when playlist_id param is present' do
    assign(:query, 'test')
    assign(:tracks, [
      { name: 'Track A', artists: 'Artist A', album: 'Album A', external_url: 'http://last.fm/1' }
    ])

    allow(view).to receive(:params).and_return(ActionController::Parameters.new(q: 'test', playlist_id: '42'))

    render
    expect(rendered).to match(/Add to playlist/)
    expect(rendered).to match(/form/) # ensure form is present
  end
end
