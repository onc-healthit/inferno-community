# frozen_string_literal: true

require_relative './local_ndjson_service'

module Inferno
  class NDJsonFactory
    # Create an instance of an NDJson service based on the configured type in config.yml
    def self.create_service(type, testing_instance)
      case type
      when :local
        LocalNDJsonService.new(testing_instance)
      else
        raise "No implemented ndjson service of type #{type}"
      end
    end
  end
end
