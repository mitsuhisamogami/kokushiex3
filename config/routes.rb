Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    post 'users/guest_sign_in', to: 'users/sessions#guest_sign_in'
    delete 'users/guest_sign_out', to: 'users/sessions#guest_sign_out'
  end

  root to: 'top#index'
  get '/dashboard' => 'dashboard#index'
  # TODO: registrationのeditをaccountにしたい
  get '/account' => 'accounts#show'

  namespace :tests do
    get '/select' => 'selections#index'
  end
  get '/tests/:id' => 'tests#show', as: 'test'
  resources :mini_tests, only: %i[index create]

  resources :examinations do
    resources :scores, only: [:show]
  end

  resources :user_responses, only: [:create]

  get '/terms_of_use' => 'terms#use'
  get '/privacy_policy' => 'terms#privacy'

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
end
