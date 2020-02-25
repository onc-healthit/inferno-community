# frozen_string_literal: true

# Through the use of `prepend` below, this module gets included in RestClient::Request
# And can call the original `initialize` method as `super`
# Yes, this is monkey patching, but it's the cleanest way I could find to do this monkey patch
module RequestExtensions
  def initialize(args)
    args[:timeout] = Inferno::TIMEOUT unless args.include?(:timeout)
    super(args)
  end
end

module RestClient
  class Request
    prepend RequestExtensions
  end
end
