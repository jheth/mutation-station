class Build < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user

  store_accessor :result, [:env_progress, :failed_subject_results, :success_subject_results]

  def self.perform(repository_id, user_id, filter, branch='master')
    repository = Repository.find(repository_id)
    user = User.find(user_id)

    wd = repository.working_directory
    puts wd
    Dir.chdir(wd)
    puts Dir.pwd

    puts `git pull`
    puts `git checkout #{branch}`

    current_sha = `git rev-parse HEAD`
    result_json = Tempfile.new([current_sha, '.json'])
    stdout_file = Tempfile.new([current_sha, '.txt'])

    gemfile = File.join(wd, 'Gemfile')
    unless system("grep -q mutant-rspec Gemfile")
      File.open(gemfile, 'a') {|f|
        f.write(%Q{gem "mutant-rspec", github: "jheth/mutant", branch: 'json-output-reporter'})
      }
    end

    Bundler.with_clean_env do
      puts `bundle install --path=vendor`
      puts `bundle exec mutant --include lib/ --json-dump "#{result_json.path}" --use rspec #{filter} > "#{stdout_file.path}"`
    end

    if File.exist?(result_json) && File.size(stdout_file.path) > 0
      Build.create(
        repository: repository,
        user: user,
        last_sha: current_sha,
        result: JSON.parse(File.read(result_json.path)),
        stdout: File.read(stdout_file.path)
      )
    end
  end

end
