# frozen_string_literal: true

require 'ndjson'
require 'securerandom'

module Inferno
  class BaseNDJsonService
    def initialize(file_paths, testing_instance)
      @file_paths = file_paths
      @testing_instance = testing_instance
      @unique_id = SecureRandom.uuid

      path = File.expand_path('../../../../resources/quality_reporting/NDJson', __dir__)
      FileUtils.mkdir_p(path) unless File.directory?(path)
      @generator = NDJSON::Generator.new("#{path}/#{@unique_id}.ndjson")
    end

    def generate_ndjson
      @file_paths.each do |f|
        file_path = File.expand_path(f, __dir__)
        json = JSON.parse(File.read(file_path))
        @generator.write(json)
      end
    end

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

    def generate_ndjson_url
      raise 'NDJson service needs to implement the generate_ndjson_url method'
    end
  end
end
