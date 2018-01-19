class AssertionException < Exception
  attr_accessor :data
  def initialize(message, data=nil)
    super(message)
    FHIR.logger.error "AssertionException: #{message}"
    @data = data
  end
end

# WILL WE NEED THIS?
class SkipException < Exception
  def initialize(message = '')
    super(message)
    FHIR.logger.info "SkipException: #{message}"
  end
end

class TodoException < Exception
  def initialize(message = '')
    super(message)
    FHIR.logger.info "TodoException: #{message}"
  end
end

class WaitException < Exception
  attr_accessor :endpoint
  def initialize(endpoint)
    super("Waiting at endpoint #{endpoint}")
    @endpoint = endpoint
  end
end

class RedirectException < Exception
  attr_accessor :endpoint
  attr_accessor :url
  def initialize(url, endpoint)
    super("Redirecting to #{url} and waiting at endpoint #{endpoint}")
    @url = url
    @endpoint = endpoint
  end
end
