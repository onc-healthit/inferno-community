# frozen_string_literal: true

module Inferno
  class AssertionException < RuntimeError
    attr_accessor :details
    def initialize(message, details = nil)
      super(message)
      Inferno.logger.error "AssertionException: #{message}"
      @details = details
    end

    def update_result(result)
      result.fail!
      result.message = message
      result.details = details
    end
  end

  class SkipException < RuntimeError
    attr_accessor :details
    def initialize(message = '', details = nil)
      super(message)
      Inferno.logger.info "SkipException: #{message}"
      @details = details
    end

    def update_result(result)
      result.skip!
      result.message = message
      result.details = details
    end
  end

  class TodoException < RuntimeError
    def initialize(message = '')
      super(message)
      Inferno.logger.info "TodoException: #{message}"
    end

    def update_result(result)
      result.todo!
      result.message = message
    end
  end

  class PassException < RuntimeError
    def initialize(message = '')
      super(message)
      Inferno.logger.info "PassException: #{message}"
    end

    def update_result(result)
      result.pass!
      result.message = message
    end
  end

  class OmitException < RuntimeError
    def initialize(message = '')
      super(message)
      Inferno.logger.info "OmitException: #{message}"
    end

    def update_result(result)
      result.omit!
      result.message = message
    end
  end

  class WaitException < RuntimeError
    attr_accessor :endpoint
    def initialize(endpoint)
      super("Waiting at endpoint #{endpoint}")
      @endpoint = endpoint
    end

    def update_result(result)
      result.wait!
      result.wait_at_endpoint = endpoint
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

    def update_result(result)
      result.wait!
      result.wait_at_endpoint = endpoint
      result.redirect_to_url = url
    end
  end

  class MetadataException < RuntimeError
  end

  class InvalidMetadataException < RuntimeError
  end

  class InvalidKeyException < RuntimeError
  end
end

# Monkey patch common exceptions so that we don't get hard errors.
# These are runtime issues on servers, not unhandled exceptions with Inferno
[ClientException, SocketError, RestClient::Exceptions::OpenTimeout, RestClient::RequestTimeout, Errno::EADDRNOTAVAIL, Errno::ECONNRESET].each do |exception_type|
  exception_type.class_eval do
    def update_result(result)
      result.fail!
      result.message = message
    end
  end
end
