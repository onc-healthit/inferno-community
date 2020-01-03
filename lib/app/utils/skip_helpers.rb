# frozen_string_literal: true

module Inferno
  module SkipHelpers
    def skip_if_known_not_supported(resource, methods = [], operations = [])
      # In the case that the user has not run the any capability statement sequences, we
      # will allow this to silently pass because we don't know if the server supports it or not.
      return if @instance.server_capabilities.nil?

      skip_if_not_supported(resource, methods, operations)
    end

    def skip_if_not_supported(resource, methods = [], operations = [])
      skip_message = "This server does not support #{resource} #{(methods + operations).join(',')} operation(s) according to conformance statement."
      skip skip_message unless @instance.conformance_supported?(resource, methods, operations)
    end

    def omit_if_tls_disabled
      omit 'Test has been omitted because TLS tests have been disabled by configuration.' if @disable_tls_tests
    end

    def skip_if_url_invalid(url, url_name, details = nil)
      if url.blank?
        skip "The #{url_name} URI is empty.", details
      elsif !url&.match?(URI::DEFAULT_PARSER.make_regexp)
        skip "Invalid #{url_name} URI: '#{url}'", details
      end
    end
  end
end
