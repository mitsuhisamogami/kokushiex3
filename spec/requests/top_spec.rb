require 'rails_helper'

RSpec.describe 'Tops' do
  describe 'GET /' do
    it 'returns http success' do
      get '/'
      expect(response).to have_http_status(:ok)
    end
  end
end
