Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
  }, skip: ['passwords', 'sessions', 'registrations']

  devise_scope :user do
    delete '/users/log_out', to: 'devise/sessions#destroy',
                             as: :destroy_user_session
  end

  authenticated :user do
    root 'dashboard#show', as: :authenticated_user
  end

  root 'high_voltage/pages#show', id: 'home'

  resources :users, only: [] do
    resources :repositories, only: [:create, :show, :destroy]
  end

  get '/repositories/search', to: 'repositories#search'
  resources :repositories, only: [:index] do
    resources :builds
  end
end
