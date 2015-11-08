class Repository < ActiveRecord::Base
  belongs_to :user
  has_many :builds, dependent: :destroy

  validates :name, :clone_url, presence: true, uniqueness: true

  paginates_per 10

  def github_repo
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)

    client.repo(name)
  end

  def working_directory
    cwd = Rails.root.join('tmp', name)
    unless Dir.exist?(cwd)
      FileUtils.mkdir_p(cwd)

      Dir.chdir(cwd) do
        puts 'Cloning repository into...'
        response = `git clone #{clone_url} .`
        puts response
      end
    end

    cwd
  end

  def specs?
    spec_list.any?
  end

  def spec_list
    @spec_list = []

    filepath = working_directory
    if File.directory?(File.join(filepath, 'spec'))
      excluded_files = ['factories', 'rails_helper.rb', 'spec_helper.rb']
      Dir.chdir(filepath) do
        @spec_list = Dir.glob('spec/**/*.rb').reject do |x|
          excluded_files.any? { |f| x.include?(f) }
        end
      end
    end

    @spec_list
  end

  def class_list
    self.class.convert_files_to_class_list(spec_list)
  end

  def set_github_details
    gh = github_repo

    attributes = {
      clone_url: gh.clone_url,
    }

    assign_attributes(attributes)
  rescue Octokit::NotFound
    errors.add(:repository, 'cannot be located on GitHub.')
  end

  def self.convert_files_to_class_list(file_list)
    class_name_list = []
    if file_list.is_a?(Array)
      class_name_list = file_list.map do |s|
        matches = s.match(%r{spec\/lib\/([\w\/]*)_spec.rb})
        if matches.present?
          matches[1].split('/').map(&:camelize).join('::')
        end
      end.compact
    end

    class_name_list
  end

end
