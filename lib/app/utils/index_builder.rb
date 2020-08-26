# frozen_string_literal: true

require 'json'

module Inferno
  class IndexBuilder
    # @param folder [String] the path of the package to index
    def initialize(folder)
      raise ArgumentError, "'#{folder}' is not a directory" unless Dir.exist?(folder)

      package_folder = File.join(folder, 'package')
      folder = package_folder if Dir.exist?(package_folder)
      package_json = File.join(folder, 'package.json')
      raise ArgumentError, 'Could not find package.json' unless File.exist?(package_json)

      @package_root = folder
      @files = []
      @index = { 'index-version': 1, files: @files }
    end

    # @return [Boolean] whether or not the given package has been indexed
    def indexed?
      File.exist?(index_path)
    end

    # Builds the .index.json contents if it doesn't exist, otherwise immediately returns.
    # Yields the built contents if a block was given, otherwise writes it to .index.json at the root.
    def build
      return if indexed?

      Dir.chdir(@package_root) do
        Dir.glob('*.json').select { |f| File.file?(f) }.each do |filename|
          add_json_file(filename, File.read(filename))
        end
      end
      contents = JSON.pretty_generate(@index)
      block_given? ? yield(contents) : File.write(index_path, contents)
      nil
    end

    private

    # @return [String] the path where the .index.json file should be
    def index_path
      File.join(@package_root, '.index.json')
    end

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
      nil
    end
  end
end
