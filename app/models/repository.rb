class Repository < ActiveRecord::Base
  before_validation :set_github_details

  belongs_to :user

  validates :name, :clone_url, presence: true

  private

  def set_github_details
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)

    begin
      github_repo = client.repo(name)

      attributes = {
        clone_url: github_repo.clone_url,
      }

      assign_attributes(attributes)
    rescue Octokit::NotFound
      errors.add(:repository, 'cannot be located on GitHub.')
    end
  end
end
