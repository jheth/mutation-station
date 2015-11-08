source 'https://rubygems.org'

source 'https://rails-assets.org' do
  gem 'rails-assets-typehead.js'
  gem 'rails-assets-select2', '~>3.5.4'
  gem 'rails-assets-pusher'
  gem 'rails-assets-toastr'
end

ruby '2.2.3'

gem 'rails', '4.2.4'
gem 'pg'
gem 'bootstrap-sass', '~> 3.3.5'
gem 'bootswatch-rails'
gem 'font-awesome-sass', '~> 4.4.0'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'devise'
gem 'high_voltage', '~> 2.4.0'
gem 'faker'
gem 'omniauth-github'
gem 'delayed_job_active_record'
gem 'puma'
gem 'octokit', '~> 4.0'
gem 'slim'
gem 'pusher'
gem 'kaminari'
gem 'ransack'

group :production do
  gem 'rails_12factor'
end

group :development, :test do
  gem 'byebug'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.0'
  gem 'factory_girl_rails'
  gem 'dotenv-rails'
  gem 'binding_of_caller'
  gem 'pry-rails'
  gem 'awesome_print'
end

group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
end

group :test do
  gem 'shoulda-matchers', '~> 3.0'
  gem 'simplecov', require: false
  gem 'mutant-rspec', github: 'jheth/mutant', branch: 'json-output-reporter'
end
