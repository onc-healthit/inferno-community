# frozen_string_literal: true

require 'json'

module Inferno
  class IndexBuilder

    # @param folder [String] the path of the folder to index
    def initialize(folder)
      raise ArgumentError, "'#{folder}' is not a directory" unless Dir.exist?(folder)

      @folder = folder
      @files = []
      @index = { 'index-version': 1, files: @files }
    end

    # @return [Boolean] whether or not the given folder has been indexed
    def indexed?
      File.exist?(File.join(@folder, '.index.json'))
    end

    # Builds and returns the string representing the contents of an .index.json file for the given folder.
    #
    # @return [String] a string representing the contents of an .index.json file
    def build
      Dir.chdir(@folder) do
        Dir.glob('*.json').select { |f| File.file?(f) }.each do |filename|
          add_json_file(filename, File.read(filename))
        end
      end
      JSON.pretty_generate(@index)
    end

    private

    # Adds a JSON file with the given name and contents to the index being built.
    # Ignores files that don't contain a valid "resourceType" property.
    #
    # @param filename [String] the name of the file to index
    # @param contents [String] the contents of the file to index
    def add_json_file(filename, contents)
      file = JSON.parse(contents)
      return unless file.is_a?(Hash)
      return unless file['resourceType'].is_a?(String)

      file.slice!('resourceType', 'id', 'url', 'version', 'kind', 'type', 'supplements')
        .delete_if { |_, val| val.is_a?(Hash) || val.is_a?(Array) }
        .transform_values! { |val| val.is_a?(String) ? val : val.to_json }
      file['filename'] = filename
      @files << file
    end
  end
end
