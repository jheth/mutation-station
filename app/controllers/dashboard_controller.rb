class DashboardController < ApplicationController
  def show
    @repositories = Repository.page(params[:page])
  end
end
