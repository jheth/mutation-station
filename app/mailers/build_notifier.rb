class BuildNotifier < ApplicationMailer
  def build_finished(user, build)
    @user = user
    @build = build
    mail(to: @user.email, subject: "Build ##{@build.id} for #{@build.repository.name} has finished.")
  end
end
