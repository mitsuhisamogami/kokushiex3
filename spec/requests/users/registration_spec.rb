require 'rails_helper'

RSpec.describe 'Users::registrations' do
  let(:user) { create(:user) }

  def parsed_response
    Nokogiri::HTML(response.body)
  end

  describe 'GET /users/sign_up' do
    it 'ユーザー登録画面が表示される' do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
    end

    it 'Googleが無効な場合はGoogle登録ボタンを表示しない' do
      with_google_oauth_routes(enabled: false) do
        get new_user_registration_path

        expect(response.body).not_to include('Googleで登録')
      end
    end

    it 'Googleが有効な場合はPOSTのGoogle登録ボタンを表示する' do
      with_google_oauth_routes(enabled: true) do
        get new_user_registration_path
        google_form = parsed_response.at_css(
          'form[action="/users/auth/google_oauth2"][method="post"][data-turbo="false"]'
        )

        aggregate_failures do
          expect(response.body).to include('Googleで登録')
          expect(google_form).to be_present
          expect(google_form.at_css('svg')).to be_present
          expect(response.body.index('action="/users"'))
            .to be < response.body.index('action="/users/auth/google_oauth2"')
          expect(response.body).not_to include('href="/users/auth/google_oauth2"')
        end
      end
    end
  end

  describe 'POST /users/sign_up' do
    let(:valid_user_params) do
      { user: { username: 'newuser', email: 'newuser@example.com', password: 'password',
                password_confirmation: 'password' } }
    end
    let(:invalid_user_params) do
      { user: { username: '', email: 'user@example.com', password: 'password', password_confirmation: 'password' } }
    end

    context '正常系' do
      it 'ユーザー登録後ダッシュボード画面にリダイレクトされる' do
        expect do
          post user_registration_path, params: valid_user_params
        end.to change(User, :count).by(1)
        expect(response).to redirect_to(dashboard_path)
        expect(response).to have_http_status(:see_other)
      end
    end

    context '不正なパラメータの場合' do
      it 'ユーザー登録ができず新規登録画面にリダイレクトされる' do
        expect do
          post user_registration_path, params: invalid_user_params
        end.not_to change(User, :count)
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
