class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  before_filter :load_user

  def github
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      flash[:error] = I18n.t('errors.general')
      redirect_to root_path
    end
  end

  private

  def load_user
    @user = User.from_omniauth(request.env['omniauth.auth'])
  end
end
