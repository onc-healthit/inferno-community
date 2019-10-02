# frozen_string_literal: true

module Inferno
  module MeasureOperations
    # Run the $evaluate-measure operation for the given Measure
    #
    # measure_id - ID of the Measure to evaluate
    # params - hash of params to form a query in the GET request url
    def evaluate_measure(measure_id, params = {})
      params_string = params.empty? ? '' : "?#{params.to_query}"
      @client.get "Measure/#{measure_id}/$evaluate-measure#{params_string}", @client.fhir_headers(format: FHIR::Formats::ResourceFormat::RESOURCE_JSON)
    end

    def submit_data
      # TODO
      nil
    end

    def collect_data(measure_id, params = {})
      params_string = params.empty? ? '' : "?#{params.to_query}"
      @client.get "Measure/#{measure_id}/$collect-data#{params_string}", @client.fhir_headers(format: FHIR::Formats::ResourceFormat::RESOURCE_JSON)
    end

    def data_requirements
      # TODO
      nil
    end

    def get_measure_resources_by_name(measure_name)
      @client.get "Measure?name=#{measure_name}", @client.fhir_headers(format: FHIR::Formats::ResourceFormat::RESOURCE_JSON)
    end

    def async_submit_data(params_resource)
      headers = {
        'Accept': 'application/fhir+json',
        'Content-Type': 'application/json',
        'Prefer': 'respond-async',
        'Accept-Encoding': 'gzip, deflate',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
      }
      LoggedRestClient.post(@instance.url + '/$import', params_resource.to_json, headers)
    end
  end
end
