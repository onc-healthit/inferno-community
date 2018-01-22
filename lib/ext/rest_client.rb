require 'pry'
module RestClient

  attr_accessor :requests

  # figure out a way to record the headers...
  def self.record_requests(reply)
    @requests ||= []
    @requests << reply
  end

  def self.monitor_requests
    return if @decorated
    binding.pry
    @decorated = true
    [:get, :put, :post, :delete, :head, :patch].each do |method|
      class_eval %Q{
          class << self
            alias #{method}_original #{method}
            def #{method}(*args, &block)
              reply = #{method}_original(*args, &block)
              self.record_requests(reply)
              return reply
            end
          end
        }
    end
  end
end
