# frozen_string_literal: true

module Inferno
  module StartupTasks
    class << self
      def run
        check_validator_availability
        load_all_modules
      end

      def load_all_modules
        Dir.glob(File.join(__dir__, '..', '..', 'modules', '*_module.yml')).each do |file|
          this_module = YAML.load_file(file).deep_symbolize_keys
          Module.new(this_module)
        end
      end

      def check_validator_availability
        if App::Endpoint.settings.resource_validator == 'internal'
          Inferno.logger.info 'Using internal validator'
          return
        end

        validator_url = App::Endpoint.settings.external_resource_validator_url
        loop do
          Inferno.logger.info "Checking that validator is available at #{validator_url}"
          validator_version = RestClient.get("#{validator_url}/version")
          Inferno.logger.info "External validator version #{validator_version} is available"
          break
        rescue StandardError
          Inferno.logger.error "Unable to reach validator at #{validator_url}"
          sleep 1
        end
      end
    end
  end
end
