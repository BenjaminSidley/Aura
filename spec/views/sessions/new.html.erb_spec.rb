require 'rails_helper'

RSpec.describe "sessions/new.html.erb", type: :view do
  it 'renders sign in form' do
    render
    expect(rendered).to include('Sign in to Aura')
    expect(rendered).to include('Username or Email')
  end
end
