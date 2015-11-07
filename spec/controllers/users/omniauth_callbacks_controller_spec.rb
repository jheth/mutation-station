require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'routes' do
    it { should route(:get, '/users/auth/github/callback').to(action: :github) }
  end

  describe '#github' do
    context 'when the user is persisted' do
      before(:each) do
        allow(User).to receive(:from_omniauth) { FactoryGirl.create(:user) }
      end

      it 'signs in the user' do
        get :github

        expect(assigns(:user).sign_in_count).to eq(1)
      end

      it 'redirects the user to the root_path' do
        expect(get :github).to redirect_to(root_path)
      end
    end

    context 'when the user is not persisted' do
      before(:each) do
        allow(User).to receive(:from_omniauth) { FactoryGirl.build(:user) }
      end

      it 'sets a flash error message' do
        get :github

        expect(flash[:error]).to eq(I18n.t('errors.general'))
      end

      it 'redirects the user to the root_path' do
        expect(get :github).to redirect_to(root_path)
      end
    end
  end
end
