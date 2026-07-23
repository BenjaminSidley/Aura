require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  it 'has a default from address' do
    expect(ApplicationMailer.default[:from]).to eq('from@example.com')
  end
end
