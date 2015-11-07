Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
  }, skip: ['passwords', 'sessions', 'registrations']

  devise_scope :user do
    delete '/users/log_out', to: 'devise/sessions#destroy',
                             as: :destroy_user_session
  end

  root 'high_voltage/pages#show', id: 'home'

  authenticated :user do
    # root for authenticated users goes here.
    # root 'some_controller#some_page', as: :authenticated_user
  end
end
