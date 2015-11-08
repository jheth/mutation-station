require 'open3'

class BuildRunner
  def perform(build_id: nil, filter: '', branch: 'master', fail_fast: false)
    @build = Build.find(build_id)
    @repository = @build.repository
    @build.update_attributes(status: Build::RUNNING)

    @build.send_progress_status(status: Build::RUNNING, message: 'Build Started...')

    # Make sure we have the repo
    @working_dir = @repository.working_directory.to_s
    Dir.chdir(@working_dir)

    @build.send_progress_status(message: 'Pulling latest changes from github.')

    git_reset(branch)
    git_pull
    git_checkout(branch)

    current_sha = head_sha

    result_json = "#{current_sha}.json"
    stdout_file = "#{current_sha}.txt"

    build_status = Build::COMPLETE
    mutant_json = nil
    stdout_text = nil

    gemfile = File.join(@working_dir, 'Gemfile')

    Bundler.with_clean_env do
      ENV['BUNDLE_GEMFILE'] = gemfile
      ENV['BUNDLE_FROZEN'] = '0'
      @build.send_progress_status(message: 'Running bundle install...')
      if bundle_install
        # Set Up Mutant Testing
        unless system('grep -q mutant-rspec Gemfile')
          File.open(gemfile, 'a') do |f|
            f.write("\n" + mutant_gem)
          end
          log(`git diff #{gemfile}`)
          bundle_install(filter: 'mutant')
        end

        if @repository.rails_app?
          log("Attempting to setup Rails environment. Mysql is not supported.")
          @build.send_progress_status(message: 'Setting up Rails environment...')
          db_cmd = %(RAILS_ENV=test bundle exec rake db:reset)
          log(db_cmd)
          log(`#{db_cmd}`)
        end

        @build.send_progress_status(message: 'Running Mutant Tests...')
        run_mutant(filter: filter, json_out: result_json, stdout: stdout_file, fail_fast: fail_fast)

        stdout_text = File.exist?(stdout_file) ? File.read(stdout_file) : nil

        if File.exist?(result_json) && File.size(result_json) > 0
          mutant_json = JSON.parse(File.read(result_json))
          File.unlink(result_json)
        else
          build_status = Build::ERROR
          log("WARN: JSON output file does not exist.")
          @build.send_progress_status(status: Build::ERROR, message: 'Failed running mutant process. See log files.')
        end
      else
        build_status = Build::ERROR
        @build.send_progress_status(status: Build::ERROR, message: 'Failed running bundle install. See log files.')
      end
    end

    @build.update_attributes({
      status: build_status,
      last_sha: current_sha,
      result: mutant_json,
      stdout: stdout_text,
      build_log: File.read(build_log)
    })

    if build_status == Build::COMPLETE
      @build.send_progress_status(status: Build::COMPLETE, message: 'Build Complete!')
    end

    File.unlink(stdout_file) if File.exist?(stdout_file)
  rescue => e
    log(e.message)
    unless e.class == ArgumentError
      log(e.backtrace.join("\n"))
    end

    @build.update_attributes({
      status: Build::ERROR,
      last_sha: current_sha,
      build_log: File.read(build_log)
    })
    @build.send_progress_status(status: Build::ERROR, message: e.message)
  end

  def build_log
    @logfile ||= "#{head_sha}_#{Time.now.to_i}.txt"
  end

  def log(message)
    unless @logger
      @logger ||= File.open(build_log, 'w')
      @logger.sync = true
    end
    @logger.write(message + "\n")
  end

  def bundle_install(filter: nil)
    cmd = %(bundle install --path=vendor)
    cmd << %(| grep #{filter}) if filter

    log(cmd)
    stdout_str, stderr_str, status = Open3.capture3(cmd)
    log(stdout_str)
    log(stderr_str)

    status.success?
  end

  def b_exec(cmd)
    be_cmd = %(bundle exec #{cmd})
    log(be_cmd)
    log(`#{be_cmd}`)
  end

  def git_reset(branch)
    cmd = %(git reset --hard origin/#{branch})
    log(cmd)
    log(`#{cmd}`)
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

  def rspec3?
    version = `bundle show rspec-core`
    log(version)

    if version =~ /rspec-core-([\d\.]+)/
      if $1.to_f >= 3.3
        raise ArgumentError.new("Unsupported RSpec Version (#{$1}). RSpec 3.2 is the highest version supported.")
      end
      return $1.to_f >= 3.0
    else
      false
    end
  end

  def require_file
    namespace = @repository.namespace
    lib_file = nil

    if namespace.present?
      project_file = File.join(@working_dir, 'lib', "#{namespace.underscore}.rb")

      unless File.exist?(project_file)
        project_file = Dir.glob(File.join(@working_dir, 'lib', "*.rb")).first
      end
      if project_file
        project_file = File.basename(project_file)
        log("Found project file #{project_file}")
        lib_file = project_file.gsub('.rb', '')
      end
    else
      log('No gem namespace found')
    end

    lib_file
  end

  def mutant_gem
    mutant_version = rspec3? ? 'json-output-reporter' : 'rspec2-json'
    %(gem "mutant-rspec", github: "jheth/mutant", branch: '#{mutant_version}')
  end

  def run_mutant(filter: '', json_out: nil, stdout: nil, fail_fast: false)

    cmd = ["bundle exec mutant"]

    if @repository.rails_app?
      cmd.unshift("RAILS_ENV=test")
      cmd << %(-r ./config/environment)
    else
      cmd << ["--include lib/"]
      if rfile = require_file
        cmd << ["--require #{rfile}"]
      end
    end

    cmd << ["--fail-fast"] if fail_fast
    cmd << %(--json-dump #{json_out})
    cmd << %(--use rspec #{filter.join(' ')})
    cmd << %(   &> "#{stdout}")
    cmd_str = cmd.join(' ')
    log(cmd_str)
    log(`#{cmd_str}`)
  end

end
