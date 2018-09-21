module Inferno
  class AssertionException < Exception
    attr_accessor :details
    def initialize(message, details = nil)
      super(message)
      FHIR.logger.error "AssertionException: #{message}"
      @details = details
    end
  end

  class SkipException < Exception
    attr_accessor :details
    def initialize(message = '', details = nil)
      super(message)
      FHIR.logger.info "SkipException: #{message}"
      @details = details
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

  class MetadataException < Exception
  end
end
