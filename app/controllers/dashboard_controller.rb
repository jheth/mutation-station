class DashboardController < ApplicationController
  def show
    search = current_user.repositories.ransack(name_cont: params[:search])
    @repositories = search.result.page(params[:page])
  end
end
