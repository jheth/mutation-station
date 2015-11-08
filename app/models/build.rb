class Build < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  store_accessor :result, [:env_progress, :failed_subject_results,
                           :success_subject_results]

  validates :status, presence: true

  QUEUED = 0
  RUNNING = 1
  COMPLETE = 2
  ERROR = 3

  def self.bundle_install
    cmd = %(bundle install --path=vendor)
    puts cmd
    puts `#{cmd}`
  end

  def self.b_exec(cmd)
    puts %(bundle exec #{cmd})
    `bundle exec #{cmd}`
  end

  def self.mutant_gem
    %(gem "mutant-rspec", github: "jheth/mutant", branch: 'json-output-reporter')
  end

  def self.perform(repository_id, user_id, filter, branch = 'master')
    repository = Repository.find(repository_id)
    user = User.find(user_id)

    working_dir = repository.working_directory
    Dir.chdir(working_dir)
    puts working_dir
    `git checkout -- Gemfile Gemfile.lock`
    puts `git pull`
    puts `git checkout #{branch}`
    current_sha = `git rev-parse HEAD`.chomp

    result_json = working_dir.join("#{current_sha}.json")
    stdout_file = working_dir.join("#{current_sha}.txt")

    gemfile = File.join(working_dir, 'Gemfile')
    unless system('grep -q mutant-rspec Gemfile')
      File.open(gemfile, 'a') do |f|
        f.write(mutant_gem)
      end
    end

    Bundler.with_clean_env do
      ENV['BUNDLE_GEMFILE'] = gemfile
      ENV['BUNDLE_FROZEN'] = '0'
      self.bundle_install

      cmd = %{bundle exec mutant --include lib/ --json-dump "#{result_json}" --use rspec #{filter.join(' ')} > "#{stdout_file}"}
      puts cmd
      puts `#{cmd}`
    end

    Build.create!(
      repository: repository,
      user: user,
      last_sha: current_sha,
      result: JSON.parse(File.read(result_json)),
      stdout: File.read(stdout_file),
    )

    File.unlink(result_json)
    File.unlink(stdout_file)
  rescue => e
    puts e.message
    puts e.backtrace.join('\n')
  end
end
