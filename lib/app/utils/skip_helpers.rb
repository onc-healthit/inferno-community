module Inferno
  module SkipHelpers

    def skip_if_not_supported(resource, methods)

      skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

    end

    def skip_if_tls_disabled
      pass 'Test has passed because TLS tests have been disabled by configuration.' if @disable_tls_tests
    end

    def skip_if_url_invalid(url, url_name, details = nil)
      if url.blank?
        skip "The #{url_name} URI is empty.", details
      elsif !(url =~ URI::regexp)
        skip "Invalid #{url_name} URI: '#{url}'", details
      end
    end

  end
end
