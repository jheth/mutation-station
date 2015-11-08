# Preview all emails at http://localhost:3000/rails/mailers/user_notifier
class UserNotifierPreview < ActionMailer::Preview
  def welcome
    UserNotifier.send_signup_email(User.first)
  end
end
