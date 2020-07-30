# frozen_string_literal: true

require 'rubygems/package'

module Inferno
  module StartupTasks
    class << self
      def run
        check_validator_availability
        load_all_modules
      end

      def load_all_modules
        Dir.glob(File.join(__dir__, '..', '..', 'modules', '*_module.yml')).each do |file|
          module_metadata = YAML.load_file(file).deep_symbolize_keys
          Module.new(module_metadata)

          load_ig_in_validator(module_metadata) if external_validator? && module_metadata.key?(:resource_path)
        end
      end

      def external_validator?
        App::Endpoint.settings.resource_validator == 'external'
      end

      def validator_url
        App::Endpoint.settings.external_resource_validator_url
      end

      def check_validator_availability
        unless external_validator?
          Inferno.logger.info 'Using internal validator'
          return
        end

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

      def load_ig_in_validator(module_metadata)
        Inferno.logger.info "Creating ig package for #{module_metadata[:resource_path]}"
        Tempfile.open([module_metadata[:resource_path], '.tar.gz']) do |file|
          create_ig_zip(file, module_metadata)

          begin
            Inferno.logger.info "Posting IG for #{module_metadata[:title].presence || module_metadata[:name]} to validator"
            RestClient.post("#{validator_url}/igs", File.read(file.path))
          rescue StandardError => e
            Inferno.logger.error 'Unable to post IG to validator'
            Inferno.logger.error e.full_message
          end
        end
      end

      def create_ig_zip(file, module_metadata)
        resource_path = File.join(__dir__, '..', '..', '..', 'resources', module_metadata[:resource_path])
        Zlib::GzipWriter.wrap(file) do |gzip|
          Gem::Package::TarWriter.new(gzip) do |tar|
            Dir.glob(File.join(resource_path, '**', '*')).each do |full_file_path|
              next if File.directory?(full_file_path)

              content = File.read(full_file_path)
              tar_file_path = relative_path_for(full_file_path)
              tar.add_file_simple(tar_file_path, 0o0644, content.bytesize) do |io|
                io.write(content)
              end
            end
          end
        end
      end

      def relative_path_for(full_file_path)
        relative_path =
          full_file_path
            .split(File.join('resources', 'ig', ''))
            .last
            .delete_prefix("package#{File::SEPARATOR}")
        File.join('package', relative_path)
      end
    end
  end
end
