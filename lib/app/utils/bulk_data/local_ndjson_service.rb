# frozen_string_literal: true

require_relative './ndjson_service'
require_relative './ndjson_result'

module Inferno
  class LocalNDJSONService
    include NDJSONService

    def initialize(testing_instance)
      @testing_instance = testing_instance
    end

    def generate_url_and_params(file_paths)
      output_file_path, unique_id = NDJSONService.generate_ndjson(file_paths).values_at(:output_file_path, :unique_id)

      url = "#{@testing_instance.base_url + Inferno::BASE_PATH}/resources/quality_reporting/NDJson/#{unique_id}.ndjson"
      params = {
        'inputFormat': 'application/fhir+ndjson',
        'inputSource': @testing_instance.url,
        'storageDetail': {
          'type': 'https'
        },
        'input': [{
          'type': 'Bundle',
          'url': url
        }]
      }

      NDJSONResult.new(output_file_path, params, url)
    end
  end
end
