require 'rails_helper'

RSpec.describe User, type: :model do
  it { should have_many(:repositories) }

  it { should validate_presence_of(:name) }

  describe '.from_omniauth' do
    let(:auth) do
      attributes = {
        provider: 'github',
        uid: '123456789',
        name: 'Luke Skywalker',
        email: 'luke@starwars.com',
        avatar_url: 'http://avatars.github.com/luke',
        nickname: 'lukeskywalker',
        token: '641e9df4627d54c08cadc1a11ddasdfadd3c5cb6',
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

      it 'sets the github_avatar_url of the user' do
        avatar_url = created_user.github_avatar_url
        expect(avatar_url).to eq('http://avatars.github.com/luke')
      end

      it 'sets the github_username of the user' do
        expect(created_user.github_username).to eq('lukeskywalker')
      end

      it 'sets the github_access_token of the user' do
        access_token = created_user.github_access_token
        expect(access_token).to eq('641e9df4627d54c08cadc1a11ddasdfadd3c5cb6')
      end
    end
  end
end
