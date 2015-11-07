require 'rails_helper'

RSpec.describe User, type: :model do
  it { should validate_presence_of(:name) }

  describe '.from_omniauth' do
    let(:auth) do
      attributes = {
        provider: 'github',
        uid: '123456789',
        name: 'Luke Skywalker',
        email: 'luke@starwars.com',
      }

      # as_null_object lets the double receive any method and returns itself.
      double(:auth, attributes).as_null_object
    end

    context 'when the user exists' do
      it 'finds a user from the provider and uid attributes' do
        user = FactoryGirl.create(:user, provider: 'github', uid: '123456789')
        located_user = User.from_omniauth(auth)

        expect(located_user).to eq(user)
      end
    end

    context 'when the user does not exist' do
      let(:created_user) { User.from_omniauth(auth) }

      it 'creates a user from the provider and uid attributes' do
        expect(created_user.persisted?).to eq(true)
      end

      it 'sets the email of the user' do
        expect(created_user.email).to eq('luke@starwars.com')
      end

      it 'sets the password of the user' do
        expect(created_user.password.size).to eq(20)
      end

      it 'sets the name of the user' do
        expect(created_user.name).to eq('Luke Skywalker')
      end
    end
  end
end
