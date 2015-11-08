class BuildsController < ApplicationController
  layout 'application'
  before_filter :load_repository

  def create
    class_names = params['class_names']
    branch = 'master'

    @build = Build.new

    if class_names.blank?
      @build.errors.add(:base, "Select at least 1 object to test.")
    else
      @build.assign_attributes(
        repository: @repo,
        user: current_user,
        status: Build::QUEUED
      )

      if @build.save && class_names.is_a?(Array)
        BuildRunner.new.delay.perform(@build.id, class_names, branch)
      else
        @build.errors.add(:base, "Something bad happened")
        @build.errors.add(:base, "Aw Snap!")
      end
    end
    # create.js.erb
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
