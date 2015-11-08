class UserNotifier < ApplicationMailer
  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: 'Thanks for signing up for MutationStation')
  end
end
