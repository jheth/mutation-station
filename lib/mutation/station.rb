require 'mutant'
require_relative './../mutant/reporter/hash.rb'

# Mutant namespace from gem
module Mutation
  class Station

    attr_reader :results

    # Example Command Line Arguments:
    # mutant --include lib/ -j 1 --use rspec Condition
    # RAILS_ENV=test mutant -r ./config/environment -j 1 --use rspec User
    def run(rails: false, includes: 'lib', jobs: 1, class_name: nil)

      arguments = []
      if rails
        arguments += ['-r', './config/environment']
      else
        arguments += ['--include', includes]
      end

      arguments += [
        '-j', jobs.to_s,
        '--use', 'rspec', class_name
      ]

      cli = ::Mutant::CLI.call(arguments)
      bootstrap = ::Mutant::Env::Bootstrap.call(cli)
      env = ::Mutant::Runner.call(bootstrap)

      @results = ::Mutant::Reporter::Hash::Printer::EnvResult.call(env)

      env.success?
    end

  end
end