# frozen_string_literal: true

require 'rubygems/package'
require_relative './index_builder'

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
        module_name = module_metadata[:title].presence || module_metadata[:name]
        unless package_json_present? module_metadata[:resource_path]
          Inferno.logger.info "Skipping validator upload for '#{module_name}'--no package.json file."
          return
        end

        Inferno.logger.info "Creating ig package for '#{module_name}'"
        Tempfile.open([module_metadata[:resource_path], '.tar.gz']) do |file|
          create_ig_zip(file, module_metadata)

          begin
            Inferno.logger.info "Posting IG for '#{module_name}' to validator"
            RestClient.post("#{validator_url}/igs", File.read(file.path))
          rescue StandardError => e
            Inferno.logger.error 'Unable to post IG to validator'
            Inferno.logger.error e.full_message
          end
        end
      end

      def create_ig_zip(file, module_metadata)
        # Index root and all subdirectories of IG
        index_builder = Inferno::IndexBuilder.new
        ig_files(module_metadata[:resource_path])
          .select { |full_path| File.directory?(full_path) }
          .each { |full_folder_path| index_builder.execute(full_folder_path) }

        Zlib::GzipWriter.wrap(file) do |gzip|
          Gem::Package::TarWriter.new(gzip) do |tar|
            ig_files(module_metadata[:resource_path]).each do |full_file_path|
              next if File.directory?(full_file_path)

              content = File.read(full_file_path)
              tar_file_path = relative_path_for(full_file_path, module_metadata[:resource_path])
              tar.add_file_simple(tar_file_path, 0o0644, content.bytesize) do |io|
                io.write(content)
              end
            end
          end
        end
      end

      def relative_path_for(full_file_path, resource_folder)
        relative_path =
          full_file_path
            .split(File.join('resources', resource_folder, ''))
            .last
            .delete_prefix("package#{File::SEPARATOR}")
        File.join('package', relative_path)
      end

      def package_json_present?(resource_path)
        ig_files(resource_path).any? { |filename| filename.end_with? 'package.json' }
      end

      def ig_files(path)
        resource_path = File.join(__dir__, '..', '..', '..', 'resources', path)
        Dir.glob(File.join(resource_path, '**', '{*,.*}')) << resource_path
      end
    end
  end
end
