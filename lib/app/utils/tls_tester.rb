# frozen_string_literal: true

require 'net/http'
require 'openssl'
module Inferno
  class TlsTester
    def initialize(params)
      if params[:uri].nil?
        if !(params[:host].nil? || params[:port].nil?)
          @host = params[:host]
          @port = params[:port]
        else
          raise ArgumentError, '"uri" or "host"/"port" required by TlsTester'
        end
      else
        @uri = URI(params[:uri])
        @host = @uri.host
        @port = @uri.port
      end
    end

    def self.testing_supported?
      !(defined? OpenSSL::SSL::TLS1_2_VERSION).nil?
    end

    def verify_ensure_protocol(ssl_version)
      http = Net::HTTP.new(@host, @port)
      http.use_ssl = true
      http.min_version = ssl_version
      http.max_version = ssl_version
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      begin
        http.request_get(@uri)
      rescue StandardError => e
        return false, "Caught TLS Error: #{e.message}", %(
          The following error was returned when the application attempted to connect to the server:

          #{e.message}

          The following parameters were used:

          ```
          host: #{@host}
          port: #{@port}
          ssl version: #{ssl_version}
          PEER verify mode
          ```
        )
      end
      [true, 'Allowed Connection with TLSv1_2']
    end

    def verify_deny_protocol(ssl_version, readable_version)
      http = Net::HTTP.new(@host, @port)
      http.use_ssl = true
      http.min_version = ssl_version
      http.max_version = ssl_version
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      begin
        http.request_get(@uri)
      rescue StandardError => e
        return true, "Correctly denied connection error of type #{e.class} happened, message is #{e.message}"
      end
      [false, "Must deny access to clients requesting #{readable_version}"]
    end

    def verify_ensure_tls_v1_2
      verify_ensure_protocol(OpenSSL::SSL::TLS1_2_VERSION)
    end

    def verify_deny_tls_v1
      verify_deny_protocol(OpenSSL::SSL::TLS1_VERSION, 'TLSv1.0')
    end

    def verify_deny_ssl_v3
      verify_deny_protocol(OpenSSL::SSL::SSL3_VERSION, 'SSLv3.0')
    end

    def verify_deny_tls_v1_1
      verify_deny_protocol(OpenSSL::SSL::TLS1_1_VERSION, 'TLSv1.1')
    end
  end
end
