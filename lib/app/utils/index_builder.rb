# frozen_string_literal: true

require 'json'

module Inferno
  class IndexBuilder
    @files = nil
    @index = nil

    # Prepares the IndexBuilder to start indexing files
    # @return [nil]
    def start
      @files = []
      @index = { 'index-version': 1, files: @files }
      nil
    end

    # Indexes the file with the given name and contents.
    # @param filename [String] the name of the file to index
    # @param contents [String] the contents of the file to index
    # @return [Boolean] true, unless there was an error parsing and the filename contained "openapi" (then false)
    def see_file(filename, contents)
      return true unless filename.end_with?('.json')

      begin
        json = JSON.parse(contents)
      rescue JSON::ParserError => e
        Inferno.logger.error("Error parsing #{filename}: #{e.message}")
        return !filename.include?('openapi')
      end

      return true unless json.is_a?(Hash)
      return true unless (type = json['resourceType'])

      file = { filename: filename, resourceType: type.to_s }
      props = json.slice('id', 'url', 'version', 'kind', 'type', 'supplements')
        .reject { |_, val| val.is_a?(Hash) || val.is_a?(Array) }
        .transform_values { |val| val.is_a?(String) ? val : val.to_json }
      @files << file.merge(props)

      true
    end

    # Builds and returns the string representing the contents of an .index.json file.
    # @return [String] a string representing the contents of the .index.json file
    def build
      index = JSON.pretty_generate(@index)
      @files = nil
      @index = nil
      index
    end

    # Indexes the folder at the given path <folder> or at <folder>/package if not already indexed.
    # @param folder [String] the path of the folder to index
    # @return [Boolean] whether a new .index.json was created
    # @raise [StandardError] if there was an error reading a file
    def execute(folder)
      folder_package = File.join(folder, 'package')
      (folder = folder_package) if Dir.exist?(folder_package)

      Dir.chdir(folder) do
        return false if File.exist?('.index.json')

        start
        Dir.glob('*.json').select { |f| File.file?(f) }.each do |filename|
          see_file(filename, File.read(filename))
        end
        File.write('.index.json', build)
      end

      true
    end
  end
end
