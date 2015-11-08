class BuildsController < ApplicationController
  layout 'application'
  before_filter :load_repository

  def create
    class_names = params['class_names']
    branch = 'master'

    if class_names.is_a?(Array)
      Build.delay.perform(@repo.id, current_user.id, class_names, branch)
    end

    head :no_content
  end

  def index
    @builds = @repo.builds
  end

  def show
    @build = Build.find(params[:id])
    @spec_list = @repo.spec_list
    @result_data = @build.result
  end

  private

  def load_repository
    @repo = Repository.find(params[:repository_id])
  end
end
