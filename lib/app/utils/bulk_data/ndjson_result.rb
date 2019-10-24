# frozen_string_literal: true

module Inferno
  # Class representing the result of NDJSON generation from any of the NDJSON services
  class NDJSONResult
    attr_accessor :output_file_path
    attr_accessor :params
    attr_accessor :url

    # output_file_path - String for the abolute path location of the generated .ndjson file
    # params - Hash of the payload for bulk data $import
    # url - String for the GETtable url of the ndjson file
    def initialize(output_file_path, params, url)
      @output_file_path = output_file_path
      @params = params
      @url = url
    end
  end
end
