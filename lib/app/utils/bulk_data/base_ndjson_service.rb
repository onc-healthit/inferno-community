# frozen_string_literal: true

require 'ndjson'
require 'securerandom'

module Inferno
  class BaseNDJsonService
    attr_accessor :output_file_path

    # file_paths - array of strings that correspond to file paths of FHIR Bundles
    # testing_instance - Inferno::Models::TestingInstance for the current sequence using the NDJson Service
    def initialize(file_paths, testing_instance)
      @file_paths = file_paths
      @testing_instance = testing_instance
      @unique_id = SecureRandom.uuid

      # Local directory where we will keep the generated ndjson files
      ndjson_path = File.expand_path('../../../../resources/quality_reporting/NDJson', __dir__)
      FileUtils.mkdir_p(ndjson_path) unless File.directory?(ndjson_path)

      @output_file_path = "#{ndjson_path}/#{@unique_id}.ndjson"
      @generator = NDJSON::Generator.new(@output_file_path)
    end

    # Writes the contents of each Bundle to one .ndjson file
    def generate_ndjson
      @file_paths.each do |f|
        file_path = File.expand_path(f, __dir__)
        json = JSON.parse(File.read(file_path))
        @generator.write(json)
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
