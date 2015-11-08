class DashboardController < ApplicationController
  before_filter :authenticate_user!

  def show
    search = current_user.repositories.ransack(name_cont: params[:search])
    @repositories = search.result.page(params[:personal_page])
    @public_repositories = Repository.all.page(params[:public_page])
  end
end
