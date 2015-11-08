class BuildRunner
  def perform(repository_id, user_id, filter, branch = 'master')
    binding.pry
    repository = Repository.find(repository_id)
    user = User.find(user_id)

    working_dir = repository.working_directory
    Dir.chdir(working_dir)
    puts working_dir

    git_reset
    git_pull
    git_checkout(branch)

    current_sha = head_sha

    result_json = "#{current_sha}.json"
    stdout_file = "#{current_sha}.txt"

    gemfile = File.join(working_dir, 'Gemfile')
    unless system('grep -q mutant-rspec Gemfile')
      File.open(gemfile, 'a') do |f|
        f.write(mutant_gem)
      end
    end

    Bundler.with_clean_env do
      ENV['BUNDLE_GEMFILE'] = gemfile
      ENV['BUNDLE_FROZEN'] = '0'
      bundle_install
      run_mutant(filter, result_json, stdout_file)
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

  def log(message)
    @logger ||= File.open("#{head_sha}_#{Time.now.to_s(:db).gsub(' ', '_')}.txt", 'w')
    unless @logger.sync
      @logger.sync = true
    end

    @logger.write(message + "\n")
  end

  def bundle_install
    cmd = %(bundle install --path=vendor)
    log(cmd)
    log(`#{cmd}`)
  end

  def b_exec(cmd)
    be_cmd = %(bundle exec #{cmd})
    log(be_cmd)
    log(`#{be_cmd}`)
  end

  def git_reset
    `git checkout -- Gemfile Gemfile.lock`
    log('git checkout .')
  end

  def git_pull
    cmd = 'git pull'
    log(cmd)
    log(`#{cmd}`)
  end

  def git_checkout(branch='master')
    cmd = "git checkout #{branch}"
    log(cmd)
    log(`#{cmd}`)
  end

  def head_sha
    `git rev-parse HEAD`.chomp
  end

  def mutant_gem
    %(gem "mutant-rspec", github: "jheth/mutant", branch: 'json-output-reporter')
  end

  def run_mutant(filter, result_json, stdout_file)
    cmd = %(bundle exec mutant --include lib/ --json-dump "#{result_json}" --use rspec #{filter.join(' ')} > "#{stdout_file}")
    log(cmd)
    log(`#{cmd}`)
  end

end