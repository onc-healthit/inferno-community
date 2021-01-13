# frozen_string_literal: true

require 'rubygems/package'
require 'json'
require_relative './index_builder'
require_relative '../models/module'

module Inferno
  module StartupTasks
    class << self
      def run
        establish_db_connection
        check_validator_availability
        load_all_sequences
        load_all_modules
      end

      def load_all_modules
        Dir.glob(File.join(__dir__, '..', '..', 'modules', '*_module.yml')).each do |file|
          module_metadata = YAML.load_file(file).deep_symbolize_keys
          Inferno::Module.new(module_metadata)

          load_ig_in_validator(module_metadata) if external_validator? && module_metadata.key?(:resource_path)
        end
      end

      def load_all_sequences
        Dir.glob(File.join(__dir__, '..', '..', 'modules', '**', '*_sequence.rb')).sort.each { |file| require file }
      end

      def establish_db_connection
        path = File.join(__dir__, '..', '..', '..', 'db', 'config.yml')
        configuration = YAML.load_file(path)[ENV['RACK_ENV']]
        ActiveRecord::Base.establish_connection(configuration)
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

      def load_profiles_in_validator(module_metadata)
        resource_name = module_metadata[:resource_path]
        resource_file_glob(resource_name, '*.json') do |filename, contents|
          next unless JSON.parse(contents)['resourceType'] == 'StructureDefinition'

          RestClient.post("#{validator_url}/profiles", contents)
        rescue JSON::ParserError
          Inferno.logger.error "'#{filename}' was not valid JSON"
        rescue StandardError => e
          Inferno.logger.error "Unable to post profile '#{filename}' to validator"
          Inferno.logger.error e.full_message
        end
      end

      def load_ig_in_validator(module_metadata)
        module_name = module_metadata[:title].presence || module_metadata[:name]
        unless package_json_present? module_metadata[:resource_path]
          Inferno.logger.info "Uploading standalone profiles for '#{module_name}'"
          load_profiles_in_validator(module_metadata)
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
        resource_name = module_metadata[:resource_path]
        Zlib::GzipWriter.wrap(file) do |gzip|
          Gem::Package::TarWriter.new(gzip) do |tar|
            # Add a generated index file directly to the tarball if it didn't exist
            Inferno::IndexBuilder.new(resource_path(resource_name)).build do |content|
              tar.add_file_simple('package/.index.json', 0o0644, content.bytesize) do |io|
                io.write(content)
              end
            end
            # Add existing package files to tarball
            ig_files(resource_name) do |rel_path, content|
              tar_file_path = File.join('package', rel_path)
              tar.add_file_simple(tar_file_path, 0o0644, content.bytesize) do |io|
                io.write(content)
              end
            end
          end
        end
      end

      def package_json_present?(resource_name)
        ig_files(resource_name).include?('package.json')
      end

      def resource_path(resource_name)
        File.join(__dir__, '..', '..', '..', 'resources', resource_name)
      end

      def resource_file_glob(resource_name, pattern)
        base = resource_path(resource_name)
        unless block_given?
          return Dir.glob(pattern, base: base)
              .reject { |f| File.directory?(File.join(base, f)) }
        end

        Dir.glob(pattern, base: base) do |rel_path|
          full_path = File.join(base, rel_path)
          yield(rel_path, File.read(full_path)) unless File.directory?(full_path)
        end
      end

      def ig_files(resource_name, &block)
        resource_file_glob(resource_name, File.join('**', '{*,.*}'), &block)
      end
    end
  end
end
