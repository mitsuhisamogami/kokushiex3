require 'rails_helper'

RSpec.describe 'Dashboards' do
  describe 'GET /index' do
    let(:user) { create(:user) }

    context '認証済みユーザーの場合' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get '/dashboard'
        expect(response).to have_http_status(:success)
      end

      context '受験履歴がある場合' do
        let(:latest_test) { create(:test, year: '2024') }
        let(:old_test) { create(:test, year: '2023') }
        let!(:latest_pass_mark) do
          create(:pass_mark, test: latest_test, total_score: 200, required_practical_score: 40, required_score: 160)
        end
        let!(:old_pass_mark) do
          create(:pass_mark, test: old_test, total_score: 200, required_practical_score: 35, required_score: 150)
        end
        let!(:latest_examination) do
          create(:examination, test: latest_test, user:, attempt_date: Time.zone.local(2024, 6, 2, 10, 0, 0))
        end
        let!(:old_examination) do
          create(:examination, test: old_test, user:, attempt_date: Time.zone.local(2023, 5, 1, 10, 0, 0))
        end
        let!(:latest_score) do
          create(:score, examination: latest_examination, common_score: 80, practical_score: 70, total_score: 150)
        end
        let!(:old_score) do
          create(:score, examination: old_examination, common_score: 75, practical_score: 65, total_score: 140)
        end

        it '最新の受験結果を前回のスコアとして表示する' do
          get '/dashboard'

          expect(response.body).to include('前回のスコア')
          expect(response.body).to include('受験日：2024年06月02日')
          expect(response.body).to include('第59回(2024年度)')
          expect(response.body).to include('80')
          expect(response.body).to include('70')
          expect(response.body).to include('150')
          expect(response.body).to include('40')
          expect(response.body).to include('160')
          expect(Capybara.string(response.body)).to have_link('レポートを確認する',
                                                              href: examination_path(latest_examination))
        end

        it '受験履歴を新しい順で表示し、各レポートへのリンクを表示する' do
          get '/dashboard'

          html = Capybara.string(response.body)
          history = html.find("[data-testid='examination-history']")
          rows = history.all('tbody tr')

          expect(rows.size).to eq(2)
          expect(rows[0]).to have_text('2024年06月02日')
          expect(rows[0]).to have_text('第59回(2024年度)')
          expect(rows[0]).to have_text('80')
          expect(rows[0]).to have_text('70')
          expect(rows[0]).to have_text('150')
          expect(rows[0]).to have_text('160')
          expect(rows[0]).to have_link('確認する', href: examination_path(latest_examination))
          expect(rows[1]).to have_text('2023年05月01日')
          expect(rows[1]).to have_text('第58回(2023年度)')
          expect(rows[1]).to have_link('確認する', href: examination_path(old_examination))
        end
      end

      context '受験履歴がない場合' do
        it '空状態メッセージを表示する' do
          get '/dashboard'

          expect(response).to have_http_status(:success)
          expect(response.body).to include('受験履歴はまだありません。')
          expect(response.body).not_to include('data-testid=\'examination-history\'')
        end
      end

      context '受験履歴が11件ある場合' do
        let(:test) { create(:test, year: '2024') }
        let!(:pass_mark) { create(:pass_mark, test:) }
        let!(:examinations) do
          Array.new(11) do |index|
            examination = create(:examination,
                                 test:,
                                 user:,
                                 attempt_date: Time.zone.local(2024, 1, index + 1, 10, 0, 0))
            create(:score,
                   examination:,
                   common_score: index + 1,
                   practical_score: index + 2,
                   total_score: index + 3)
            examination
          end
        end

        it '受験履歴を10件ごとにページングする' do
          get '/dashboard'

          html = Capybara.string(response.body)
          history = html.find("[data-testid='examination-history']")
          rows = history.all('tbody tr')

          expect(rows.size).to eq(10)
          expect(rows[0]).to have_text('2024年01月11日')
          expect(rows[9]).to have_text('2024年01月02日')
          expect(history).not_to have_text('2024年01月01日')
          expect(html).to have_link('次へ', href: dashboard_path(page: 2))

          get '/dashboard', params: { page: 2 }

          html = Capybara.string(response.body)
          history = html.find("[data-testid='examination-history']")
          rows = history.all('tbody tr')

          expect(rows.size).to eq(1)
          expect(rows[0]).to have_text('2024年01月01日')
          expect(html).to have_link('前へ', href: dashboard_path(page: 1))
        end
      end
    end

    context '未認証ユーザーの場合' do
      it 'ログインページにリダイレクトされる' do
        get '/dashboard'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
