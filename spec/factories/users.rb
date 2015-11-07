FactoryGirl.define do
  factory :user do
    name 'Luke Skywalker'
    email 'luke@starwars.com'
    password Faker::Internet.password(8)
  end
end
