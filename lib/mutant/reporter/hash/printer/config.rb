module Mutant
  class Reporter
    class Hash
      class Printer
        # Printer for mutation config
        class Config < self

          # Report configuration
          #
          # @param [Mutant::Config] config
          #
          # @return [undefined]
          #
          # @api private
          def run
            {
              matcher: object.matcher.inspect,
              integration: object.integration,
              expect_coverage: object.expected_coverage * 100,
              jobs: object.jobs,
              includes: object.includes,
              requires: object.requires
            }
          end

        end # Config
      end # Printer
    end # CLI
  end # Reporter
end # Mutant
