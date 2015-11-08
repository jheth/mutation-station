class Repository < ActiveRecord::Base
  belongs_to :user
  has_many :builds, dependent: :destroy

  validates :name, :clone_url, presence: true, uniqueness: true


  paginates_per 10

  QUEUED = 0
  IN_PROGRESS = 1
  COMPLETE = 2
  ERROR = 3

  def github_repo
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)

    client.repo(name)
  end

  def working_directory
    Rails.root.join('tmp', name)
  end

  def cloned?
    self.clone_status == COMPLETE
  end

  def clone
    cwd = Rails.root.join('tmp', name)
    unless Dir.exist?(cwd) && Dir.exist?(File.join(cwd, '.git'))
      FileUtils.mkdir_p(cwd)

      Dir.chdir(cwd) do
        self.update_column(:clone_status, IN_PROGRESS)
        send_clone_status('cloning', 'Cloning repository into...')
        response = system("git clone #{clone_url} .")

        if response
          self.update_column(:clone_status, COMPLETE)
          status = 'success'
          message = "Repository #{self.name} is ready!"
        else
          self.update_column(:clone_status, ERROR)
          status = 'error'
          message = "An error occurred while cloning #{self.name}."
        end
        send_clone_status(status, message)
      end
    end
  end

  def specs?
    spec_list.any?
  end

  def spec_list
    @spec_list = []

    filepath = working_directory
    if File.directory?(File.join(filepath, 'spec'))
      Dir.chdir(filepath) do
        @spec_list = Dir.glob('spec/**/*_spec.rb')
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

  def send_clone_status(status, message)
    # Send Pusher on status/value changes
    begin
      hash = {
        id: self.id,
        status: status,
        status_text: message,
        url: "/repositories/#{self.id}",
      }
      Pusher.trigger('status_channel', 'client-repository-status', hash)
    rescue Pusher::Error => e
      # (Pusher::AuthenticationError, Pusher::HTTPError, or Pusher::Error)
    end
  end

  def self.convert_files_to_class_list(file_list)
    class_name_list = []
    if file_list.is_a?(Array)
      class_name_list = file_list.map do |s|
        matches = s.match(%r{spec\/(?:lib|unit)\/([\w\/]*)_spec.rb})
        if matches.present?
          matches[1].split('/').map(&:camelize).join('::')
        end
      end.compact
    end

    class_name_list
  end

end
