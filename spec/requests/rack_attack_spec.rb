require 'rails_helper'

RSpec.describe 'Rack::Attack' do
  before do
    # Rack::Attackのキャッシュをクリア
    Rack::Attack.cache.store.clear
  end

  describe 'ユーザー登録のレート制限' do
    let(:valid_params) do
      {
        user: {
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    it '1時間に3回までユーザー登録できる' do
      3.times do |i|
        params = valid_params.deep_dup
        params[:user][:email] = "test#{i}@example.com"
        post user_registration_path, params: params
        expect(response).to have_http_status(:see_other).or(have_http_status(:found))
      end
    end

    it '1時間に4回目のユーザー登録はレート制限される' do
      3.times do |i|
        params = valid_params.deep_dup
        params[:user][:email] = "test#{i}@example.com"
        post user_registration_path, params: params
      end

      params = valid_params.deep_dup
      params[:user][:email] = 'test3@example.com'
      post user_registration_path, params: params
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'ログイン試行のレート制限' do
    let(:user) do
      User.create(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end
    let(:login_params) { { user: { email: user.email, password: 'wrongpassword' } } }

    before do
      user
    end

    it '5分間に5回までログイン試行できる' do
      5.times do
        post user_session_path, params: login_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it '5分間に6回目のログイン試行はレート制限される' do
      5.times do
        post user_session_path, params: login_params
      end

      post user_session_path, params: login_params
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'ゲストユーザー作成のレート制限' do
    it '1時間に10回までゲストユーザー作成できる' do
      10.times do
        post users_guest_sign_in_path
        expect(response).to have_http_status(:found)
        delete destroy_user_session_path
      end
    end

    it '1時間に11回目のゲストユーザー作成はレート制限される' do
      10.times do
        post users_guest_sign_in_path
        delete destroy_user_session_path
      end

      post users_guest_sign_in_path
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe '試験提出のレート制限' do
    let(:user) { create(:user) }
    let(:test) { create(:test) }
    let(:test_session) { create(:test_session, test: test) }
    let(:questions) { create_list(:question, 5, test_session: test_session) }
    let(:choices) do
      questions.map do |question|
        create(:choice, question: question, is_correct: true)
      end
    end
    let(:valid_params) do
      {
        test_id: test.id,
        user_response: {
          choice_ids: choices.map(&:id)
        }
      }
    end

    before do
      sign_in user
      choices # データを準備
    end

    it '5分間に1回まで試験提出できる' do
      post user_responses_path, params: valid_params
      expect(response).to have_http_status(:found)
    end

    it '5分間に2回目の試験提出はレート制限される' do
      post user_responses_path, params: valid_params
      expect(response).to have_http_status(:found)

      post user_responses_path, params: valid_params
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
