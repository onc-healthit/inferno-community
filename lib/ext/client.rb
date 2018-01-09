module FHIR

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
        class_eval %Q{
          alias #{method}_original #{method}
          def #{method}(*args, &block)
            reply = #{method}_original(*args, &block)
            record_requests(reply)
            return reply
          end
        }
      end
    end
  end
end
