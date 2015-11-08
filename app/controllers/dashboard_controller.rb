class DashboardController < ApplicationController
  def show
    search = @repositories = Repository.ransack(name_cont: params[:search])
    @repositories = search.result.page(params[:page])
  end
end
