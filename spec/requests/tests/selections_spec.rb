require 'rails_helper'

RSpec.describe 'Tests::Selections' do
  describe 'GET /tests/select' do
    it '年度の降順でテストを表示する' do
      create(:test, year: '2024')
      create(:test, year: '2026')
      create(:test, year: '2025')

      get tests_select_path

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/第61回（2026年度）.*第60回（2025年度）.*第59回（2024年度）/m)
    end
  end
end
