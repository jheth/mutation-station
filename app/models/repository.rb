class Repository < ActiveRecord::Base
  belongs_to :user
  has_many :builds, dependent: :destroy

  validates :name, :clone_url, presence: true, uniqueness: true
  validate :check_eligibility

  paginates_per 5

  # Put cloning into the queue to avoid long wait times.
  # after_create { self.delay.clone }

  QUEUED = 0
  IN_PROGRESS = 1
  COMPLETE = 2
  ERROR = 3

  def octokit_client
    id = ENV.fetch('GITHUB_CLIENT_ID')
    secret = ENV.fetch('GITHUB_CLIENT_SECRET')
    client = Octokit::Client.new(client_id: id, client_secret: secret)
  end

  def github_url
    self.clone_url.gsub('.git', '')
  end

  def working_directory
    cwd = Rails.root.join('tmp', name)
    # Clone it.
    self.clone
    cwd
  end

  def cloned?
    self.clone_status == COMPLETE && Dir.exist?(working_directory)
  end

  def re_clone
    self.update_column(:clone_status, QUEUED)
    self.delay.clone
  end

  def clone
    cwd = Rails.root.join('tmp', name)
    if Dir.exist?(cwd) && Dir.exist?(File.join(cwd, '.git'))
      self.update_column(:clone_status, COMPLETE)
      #send_clone_status('success', "Repository #{self.name} is ready!")
    else
      FileUtils.mkdir_p(cwd)

      Dir.chdir(cwd) do
        self.update_column(:clone_status, IN_PROGRESS)
        send_clone_status('cloning', 'Cloning repository into...')
        response = system("git clone --depth 1 #{clone_url} .")

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
    convert_files_to_class_list(spec_list)
  end

  def rails_app?
    gemfile = File.join(working_directory, 'Gemfile')
    @rails ||= system(%{grep -q rails #{gemfile}})
  end

  def set_github_details
    gh = octokit_client.repo(name)

    unless gh.language == 'Ruby'
      errors.add(:repository, 'must be a Ruby application.')
    end

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

  def namespace
    return nil if rails_app?

    unless @namespace
      gemspec_file = Dir.glob(File.join(working_directory, "*.gemspec")).first
      @namespace = ''

      if gemspec_file
        contents = File.read(gemspec_file)
        if contents =~ /version\s*=\s*(\w+)::VERSION/
          @namespace = $1
        else
          # try gemspec filename
          @namespace = File.basename(gemspec_file).gsub('.gemspec', '')
        end
      end
    end
    @namespace
  end

  def convert_files_to_class_list(file_list)
    class_name_list = []
    if file_list.is_a?(Array)
      class_name_list = file_list.map do |s|
        matches = s.match(%r{spec\/(?:lib\/|unit\/)?([\w\/]*)_spec.rb})
        if matches.present?
          tokens = matches[1].split('/')
          # Exclude common folders
          if rails_app?
            if ['features', 'requests', 'routing', 'views'].include?(tokens.first)
              nil
            elsif ['models', 'controllers', 'helpers', 'mailers'].include?(tokens.first)
              tokens.shift
            end
          elsif namespace.present? && tokens.first != namespace
            # Watch out for case sensitivity issues.
            if tokens.first.downcase == namespace.downcase
              tokens[0] = namespace
            else
              tokens.unshift(namespace)
            end
          end
          tokens.map(&:camelize).join('::')
        end
      end.compact
    end

    class_name_list
  end

  def check_eligibility
    gh = octokit_client.repo(name)

    unless gh.language == 'Ruby'
      errors.add(:repository, 'must be a Ruby application.')
      return false
    end

    begin
      octokit_client.contents(name, path: 'spec')
    rescue Octokit::NotFound
      errors.add(:repository, 'must use RSpec and have a spec folder.')
    end
  end
end
