# frozen_string_literal: true

require_relative './base_ndjson_service'

module Inferno
  class LocalNDJsonService < BaseNDJsonService
    def initialize(file_paths, testing_instance)
      super(file_paths, testing_instance)
    end

    def generate_ndjson_url
      "#{@testing_instance.base_url + Inferno::BASE_PATH}/resources/quality_reporting/NDJson/#{@unique_id}.ndjson"
    end
  end
end
