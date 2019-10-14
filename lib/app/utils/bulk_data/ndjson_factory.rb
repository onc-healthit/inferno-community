# frozen_string_literal: true

require_relative './local_ndjson_service'

module Inferno
  class NDJsonFactory
    def self.get_service(type, files, testing_instance)
      case type
      when :local
        LocalNDJsonService.new(files, testing_instance)
      else
        raise "No implemented ndjson service of type #{type}"
      end
    end
  end
end
