class RepositoriesController < ApplicationController
  def create
    @repository = current_user.repositories.new(repository_params)
    @repository.set_github_details

    if @repository.save
      flash[:notice] = "#{@repository.name} has been added."
    else
      flash[:error] = "#{@repository.errors.full_messages}"
    end

    redirect_to root_path
  end

  def show
    @repo = Repository.find(params[:id])
    # @gh_repo = @repo.github_repo
    @builds = @repo.builds

    @spec_list = @repo.class_list
    @spec_list_tag_str = @spec_list.join(',')
  end

  def search
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)
    render json: client.search_repositories(params[:term]).items.map(&:full_name)
  end

  private

  def repository_params
    params.require(:repository).permit(:name)
  end
end
