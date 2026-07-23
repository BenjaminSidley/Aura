require 'rails_helper'

RSpec.describe "users/new.html.erb", type: :view do
  it 'renders sign up form' do
    assign(:user, User.new)
    render
    expect(rendered).to include('Sign up for Aura')
    expect(rendered).to include('Full Name')
  end
end
