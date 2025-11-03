require 'rails_helper'
require 'time'

RSpec.describe 'Users::sessions' do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.local(2025, 1, 1, 12, 0, 0) }

  around do |example|
    travel_to(current_time) { example.run }
  end

  def cookie_header(name)
    Array(response.get_header('Set-Cookie'))
      .flat_map { |header| header.split("\n") }
      .find { |header| header.start_with?("#{name}=") }
  end

  describe 'POST /users/sign_in' do
    let(:user) do
      User.create(username: 'testuser', email: 'testuser@example.com', password: 'password',
                  password_confirmation: 'password')
    end
    let(:valid_login_params) { { user: { email: 'testuser@example.com', password: 'password' } } }
    let(:invalid_login_params) { { user: { email: 'testuser@example.com', password: '123456789' } } }

    context '正常系' do
      it 'ログイン後ダッシュボード画面にリダイレクトされる' do
        user
        post user_session_path, params: valid_login_params
        expect(response).to redirect_to(dashboard_path)
        expect(response).to have_http_status(:see_other)
      end

      it 'セッションCookieにHttpOnlyとSameSite=Laxが付与され24時間後に失効する' do
        user
        post user_session_path, params: valid_login_params
        session_cookie = cookie_header('_kokushiex_session')
        expect(session_cookie).to be_present

        aggregate_failures do
          normalized = session_cookie.downcase
          expect(normalized).to include('httponly')
          expect(normalized).to include('samesite=lax')
          expect(normalized).not_to include(' secure')

          expires = session_cookie[/expires=([^;]+)/i, 1]
          expect(expires).to be_present
          expect(Time.httpdate(expires)).to be_within(1.second).of(24.hours.from_now.utc)
        end
      end

      it 'Remember Me CookieにHttpOnlyとSameSite=Laxが付与され7日後に失効する' do
        user
        post user_session_path, params: { user: valid_login_params[:user].merge(remember_me: '1') }

        remember_cookie = cookie_header('remember_user_token')
        expect(remember_cookie).to be_present

        aggregate_failures do
          normalized = remember_cookie.downcase
          expect(normalized).to include('httponly')
          expect(normalized).to include('samesite=lax')
          expect(normalized).not_to include(' secure')

          expires = remember_cookie[/expires=([^;]+)/i, 1]
          expect(expires).to be_present
          expect(Time.httpdate(expires)).to be_within(1.second).of(7.days.from_now.utc)
        end
      end
    end

    context '不正なパラメータの場合' do
      it 'ログインができずログイン画面にリダイレクトされる' do
        post user_session_path, params: invalid_login_params
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '環境依存の初期化設定' do
    let(:session_initializer) { Rails.root.join('config/initializers/session_store.rb') }
    let(:devise_initializer) { Rails.root.join('config/initializers/devise.rb') }

    it '本番環境ではセッションCookieがSecure/HttpOnly/SameSite=Lax/24時間に設定される' do
      original_session_options = Rails.application.config.session_options.to_h

      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      load session_initializer

      options = Rails.application.config.session_options
      aggregate_failures do
        expect(options[:secure]).to be true
        expect(options[:httponly]).to be true
        expect(options[:same_site]).to eq(:lax)
        expect(options[:expire_after]).to eq(24.hours)
      end
    ensure
      allow(Rails).to receive(:env).and_call_original
      load session_initializer
      Rails.application.config.session_store original_session_options[:store],
                                             **original_session_options.except(:store)
    end

    it '本番環境ではRemember Me CookieもSecure/HttpOnly/SameSite=Laxで7日間に設定される' do
      original_remember_options = Devise.rememberable_options.dup
      original_remember_for = Devise.remember_for

      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      load devise_initializer

      aggregate_failures do
        expect(Devise.rememberable_options[:secure]).to be true
        expect(Devise.rememberable_options[:httponly]).to be true
        expect(Devise.rememberable_options[:same_site]).to eq(:lax)
        expect(Devise.remember_for).to eq(7.days)
      end
    ensure
      allow(Rails).to receive(:env).and_call_original
      load devise_initializer
      Devise.rememberable_options = original_remember_options
      Devise.remember_for = original_remember_for
    end
  end

  describe 'POST /users/guest_sign_in' do
    it 'ゲストユーザーとしてログインできる' do
      post users_guest_sign_in_path
      expect(response).to redirect_to(tests_select_path)
      expect(response).to have_http_status(:found)
    end
  end

  describe 'DELETE /users/guest_sign_out' do
    let(:guest_user) { User.create_guest }

    before do
      sign_in guest_user
    end

    it 'ゲストユーザーからログアウトできる' do
      delete users_guest_sign_out_path
      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:found)
    end
  end
end
