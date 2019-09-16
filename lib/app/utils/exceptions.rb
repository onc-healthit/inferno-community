# frozen_string_literal: true

module Inferno
  class AssertionException < RuntimeError
    attr_accessor :details
    def initialize(message, details = nil)
      super(message)
      Inferno.logger.error "AssertionException: #{message}"
      @details = details
    end
  end

  class SkipException < RuntimeError
    attr_accessor :details
    def initialize(message = '', details = nil)
      super(message)
      Inferno.logger.info "SkipException: #{message}"
      @details = details
    end
  end

  class TodoException < RuntimeError
    def initialize(message = '')
      super(message)
      Inferno.logger.info "TodoException: #{message}"
    end
  end

  class PassException < RuntimeError
    def initialize(message = '')
      super(message)
      Inferno.logger.info "PassException: #{message}"
    end
  end

  class OmitException < RuntimeError
    def initialize(message = '')
      super(message)
      Inferno.logger.info "OmitException: #{message}"
    end
  end

  class WaitException < RuntimeError
    attr_accessor :endpoint
    def initialize(endpoint)
      super("Waiting at endpoint #{endpoint}")
      @endpoint = endpoint
    end
  end

  class RedirectException < RuntimeError
    attr_accessor :endpoint
    attr_accessor :url
    def initialize(url, endpoint)
      super("Redirecting to #{url} and waiting at endpoint #{endpoint}")
      @url = url
      @endpoint = endpoint
    end
  end

  class MetadataException < RuntimeError
  end
end
