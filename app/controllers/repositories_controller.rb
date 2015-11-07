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

    @spec_list = @repo.spec_list
  end

  private

  def repository_params
    params.require(:repository).permit(:name)
  end
end
