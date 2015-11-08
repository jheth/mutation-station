# Preview all emails at http://localhost:3000/rails/mailers/build_notifier
class BuildNotifierPreview < ActionMailer::Preview
  def build_finished
    BuildNotifier.build_finished(User.first, Build.first)
  end
end
