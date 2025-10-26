Rails.application.routes.draw do
  require 'sidekiq/web'
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords'
  }

  devise_scope :user do
    post 'users/guest_sign_in', to: 'users/sessions#guest_sign_in'
    delete 'users/guest_sign_out', to: 'users/sessions#guest_sign_out'
  end

  root to: 'top#index'
  get '/dashboard' => 'dashboard#index'
  #　TODO：registrationのeditをaccountにしたい
  get '/account' => 'accounts#show'

  
  namespace :tests do
    get '/select' => 'selections#index'
  end
  get '/tests/:id' => 'tests#show', as: 'test'
  resources :mini_tests, only: [:index, :create]

  resources :examinations do
    resources :scores, only: [:show]
  end
  
  resources :user_responses, only: [:create]

  get '/terms_of_use' => 'terms#use'
  get '/privacy_policy' => 'terms#privacy'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Sidekiq管理画面へのアクセス制御
  require_relative '../lib/sidekiq_admin_middleware'
  Sidekiq::Web.use SidekiqAdminMiddleware
  mount Sidekiq::Web, at: '/sidekiq'
end
