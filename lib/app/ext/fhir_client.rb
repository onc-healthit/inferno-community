# frozen_string_literal: true

module FHIR
  VERSIONS = [:dstu2, :stu3, :r4].freeze

  class Client
    attr_accessor :requests

    def record_requests(reply)
      @requests ||= []
      @requests << reply
    end

    def monitor_requests
      return if @decorated

      @decorated = true
      [:get, :put, :post, :delete, :head, :patch].each do |method|
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          alias #{method}_original #{method}
          def #{method}(*args, &block)
            reply = #{method}_original(*args, &block)
            record_requests(reply)
            return reply
          end
        RUBY
      end
    end

    def self.for_testing_instance(instance)
      new(instance.url).tap do |client|
        case instance.fhir_version
        when 'stu3'
          client.use_stu3
        when 'dstu2'
          client.use_dstu2
        else
          client.use_r4
        end
        client.default_json
      end
    end
  end
end
