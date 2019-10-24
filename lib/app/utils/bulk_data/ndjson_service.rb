# frozen_string_literal: true

require 'ndjson'
require 'securerandom'

module Inferno
  module NDJSONService
    # Generate an ndjson file containing the provided Bundles
    #
    # file_paths - Array of strings that are file paths to FHIR Bundles
    #
    # Returns a hash with the output file path of the ndjson and the unique id for the file
    def self.generate_ndjson(file_paths)
      unique_id = SecureRandom.uuid

      # Local directory where we will keep the generated ndjson files
      ndjson_path = File.expand_path('../../../../resources/quality_reporting/NDJson', __dir__)
      FileUtils.mkdir_p(ndjson_path) unless File.directory?(ndjson_path)

      # Absolute path of the .ndjson file
      output_file_path = "#{ndjson_path}/#{unique_id}.ndjson"

      generator = NDJSON::Generator.new(output_file_path)
      file_paths.each do |f|
        # Ensure Bundle exists
        file_path = File.expand_path(f, __dir__)
        raise "Bundle #{file_path} not found" unless File.file?(file_path)

        begin
          # Ensure Bundle is valid json and write it to the ndjson file
          json = JSON.parse(File.read(file_path))
          generator.write(json)
        rescue JSON::ParserError
          Inferno.logger.error "Bundle #{file_path} is not valid JSON"
        end
      end

      { output_file_path: output_file_path, unique_id: unique_id }
    end
  end
end
