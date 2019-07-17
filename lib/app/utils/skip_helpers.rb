# frozen_string_literal: true

module Inferno
  module SkipHelpers
    def skip_if_not_supported(resource, methods)
      skip_message = "This server does not support #{resource} #{methods.join(',')} operation(s) according to conformance statement."
      skip skip_message unless @instance.conformance_supported?(resource, methods)
    end

    def skip_if_tls_disabled
      omit 'Test has beem ommited because TLS tests have been disabled by configuration.' if @disable_tls_tests
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
