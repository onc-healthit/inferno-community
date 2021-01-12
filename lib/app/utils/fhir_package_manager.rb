# frozen_string_literal: true

require 'rubygems/package'
require 'tempfile'
require 'zlib'
require 'json'

module Inferno
  module FHIRPackageManager
    class << self
      REGISTRY_SERVER_URL = 'https://packages.fhir.org'
      # Get the FHIR Package from the registry.
      #
      # e.g. get_package('hl7.fhir.us.core#3.1.0')
      #
      # @param [String] package The FHIR Package
      def get_package(package, destination, desired_types = [])
        package_url = package
          .split('#')
          .prepend(REGISTRY_SERVER_URL)
          .join('/')

        tar_file_name = "tmp/#{package.split('#').join('-')}.tgz"

        File.open(tar_file_name, 'w') do |output_file|
          block = proc do |response|
            response.read_body do |chunk|
              output_file.write chunk
            end
          end
          RestClient::Request.execute(method: :get, url: package_url, block_response: block)
        end

        tar = Gem::Package::TarReader.new(Zlib::GzipReader.open("tmp/#{package.split('#').join('-')}.tgz"))

        path = File.join destination.split('/')
        FileUtils.mkdir_p(path)

        tar.each do |entry|
          next if entry.directory?

          next unless entry.full_name.start_with? 'package/'

          file_name = File.basename(entry.full_name)
          next if desired_types.present? && !file_name.start_with?(*desired_types)

          resource = JSON.parse(entry.read) if file_name.end_with? '.json'
          next unless resource&.[]('url')

          encoded_name = "#{encode_name(resource['url'])}.json"
          encoded_file_name = File.join(path, encoded_name)
          if File.exist?(encoded_file_name)
            throw FileExistsException.new("#{encoded_name} already exists for #{resource['url']}") unless resource['url'] == JSON.parse(File.read(encoded_file_name))['url']
          end

          File.open(encoded_file_name, 'w') { |file| file.write(resource.to_json) }
        end
        File.delete(tar_file_name)
      end

      def encode_name(name)
        Zlib.crc32(name)
      end

      class FileExistsException < StandardError
        def initialize(value_set)
          super(value_set.to_s)
        end
      end
    end
  end
end
