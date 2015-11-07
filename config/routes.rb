Rails.application.routes.draw do
  devise_for :users, skip: ['passwords', 'sessions', 'registrations']
end
