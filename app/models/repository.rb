class Repository < ActiveRecord::Base
  before_validation :set_github_details

  belongs_to :user
  has_many :builds

  validates :name, :clone_url, presence: true

  WORKING_DIR = '/tmp'

  def github_repo
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)

    client.repo(name)
  end

  def working_directory
    cwd = File.join(WORKING_DIR, self.name)
    unless Dir.exists?(cwd)
      FileUtils.mkdir_p(cwd)

      Dir.chdir(cwd) do
        puts "Cloning repository into..."
        response = `git clone #{self.clone_url} .`
        puts response
      end
    end

    cwd
  end

  def has_specs?
    spec_list.any?
  end

  def spec_list
    @spec_list = []

    filepath = working_directory
    if File.directory?(File.join(filepath, 'spec'))
      @spec_list = Dir.glob(File.join(filepath, "spec/**/*.rb")).select{|x|
        x.exclude?('factories') && x.exclude?('rails_helper.rb') && x.exclude?('spec_helper.rb')
      }
    end

    @spec_list
  end

  private

  def set_github_details
    begin
      gh = github_repo

      attributes = {
        clone_url: gh.clone_url,
      }

      assign_attributes(attributes)
    rescue Octokit::NotFound
      errors.add(:repository, 'cannot be located on GitHub.')
    end
  end
end
