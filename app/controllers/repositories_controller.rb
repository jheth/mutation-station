class RepositoriesController < ApplicationController
  before_filter :redirect_to_existing_repository, only: :create
  before_filter :load_repository, only: [:show, :destroy]

  def create
    @repository = current_user.repositories.new(repository_params)
    @repository.set_github_details

    if @repository.save
      flash[:notice] = "#{@repository.name} has been added."
      redirect_to [@repository.user, @repository]
    else
      flash[:error] = @repository.errors.full_messages.first
      redirect_to root_path
    end

  end

  def show
    @repo = Repository.find(params[:id])
    # @gh_repo = @repo.github_repo
    @builds = @repo.builds.order('created_at desc')

    @spec_list = @repo.class_list
    @spec_list_tag_str = @spec_list.join(',')
  end

  def search
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)
    render json: client.search_repositories(params[:term]).items.map(&:full_name)
  end

  def destroy
    if @repository.destroy
      flash[:notice] = "We've deleted #{@repository.name}"
      redirect_to root_path
    else
      flash[:error] = "Aw snap! We couldn't delete that repo."
      redirect_to @repository
    end
  end

  def index
    search = Repository.ransack(name_cont: params[:search])
    @repositories = search.result.page(params[:page])
  end

  private

  def redirect_to_existing_repository
    repository = Repository.find_by_name(params[:repository][:name])
    redirect_to [repository.user, repository] if repository
  end

  def load_repository
    @repository = Repository.find(params[:id])
  end

  def repository_params
    params.require(:repository).permit(:name)
  end
end
