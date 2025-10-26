require 'rails_helper'

RSpec.describe 'Sidekiq管理画面へのアクセス制御', type: :request do
  describe 'GET /sidekiq' do
    context '未ログイン' do
      it 'ログインページにリダイレクトされる' do
        get '/sidekiq'
        # new_user_session_pathはSidekiqマウントパス内では'/sidekiq/users/sign_in'と評価されてしまうため
        # 実際のリダイレクト先である'/users/sign_in'を文字列で指定
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context '通常ユーザーでログイン' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'アクセスできない（トップページにリダイレクト）' do
        get '/sidekiq'
        # SidekiqAdminMiddlewareにより管理者でない場合はトップページにリダイレクト
        expect(response).to redirect_to('/')
      end
    end

    context '管理者ユーザーでログイン' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'アクセスできる' do
        # CI環境ではRedis接続がないためスキップ
        skip 'Redis connection required' if ENV['CI']

        get '/sidekiq'
        expect(response).to have_http_status(:success)
      end
    end
  end
end
