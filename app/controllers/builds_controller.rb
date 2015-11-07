class BuildsController < ApplicationController
  layout 'application'
  before_filter :load_repository

  def create
    filter = []
    if params['specs'].is_a?(Array)
      filter = params['specs'].map do |s|
        if matches = s.match(/spec\/lib\/([\w\/]*)_spec.rb/)
          matches[1].split('/').map {|x|
            x.camelize
          }.join('::')
        else
          nil
        end
      end.compact
    end

    branch = 'master'

    Build.delay.perform(@repo.id, current_user.id, filter, branch)

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
