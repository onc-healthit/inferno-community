# frozen_string_literal: true

require 'ndjson'
require 'securerandom'

module Inferno
  # Class for generating .ndjson files and a URL to serve them for bulk data $import
  # Subclasses must implement the generate_ndjson_url function, which should return
  # a full url where a GET request to the url will return the generated .ndjson file
  class BaseNDJSONService
    attr_accessor :output_file_path

    # testing_instance - Inferno::Models::TestingInstance for the current sequence using the NDJson Service
    def initialize(testing_instance)
      @testing_instance = testing_instance
    end

    # Writes the contents of each Bundle to one .ndjson file
    #
    # file_paths - array of strings that correspond to file paths of FHIR Bundles
    def generate_ndjson(file_paths)
      @unique_id = SecureRandom.uuid

      # Local directory where we will keep the generated ndjson files
      ndjson_path = File.expand_path('../../../../resources/quality_reporting/NDJson', __dir__)
      FileUtils.mkdir_p(ndjson_path) unless File.directory?(ndjson_path)

      # Absolute path of the .ndjson file
      @output_file_path = "#{ndjson_path}/#{@unique_id}.ndjson"

      generator = NDJSON::Generator.new(@output_file_path)
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
    end

    # Generate the payload for the bulk data $import operation
    def generate_bulk_data_params
      {
        'inputFormat': 'application/fhir+ndjson',
        'inputSource': @testing_instance.url,
        'storageDetail': {
          'type': 'https'
        },
        'input': [{
          'type': 'Bundle',
          'url': generate_ndjson_url
        }]
      }
    end

    # Generate a URL that should return the generated .ndjson file upon a GET request
    def generate_ndjson_url
      raise 'NDJson service needs to implement the generate_ndjson_url method'
    end
  end
end
