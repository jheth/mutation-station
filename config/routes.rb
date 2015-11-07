Rails.application.routes.draw do
  devise_for :users, skip: ['passwords', 'sessions', 'registrations']

  root 'high_voltage/pages#show', id: 'home'

  authenticated :user do
    # root for authenticated users goes here.
    # root 'some_controller#some_page', as: :authenticated_user
  end
end
