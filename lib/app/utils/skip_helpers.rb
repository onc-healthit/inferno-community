# frozen_string_literal: true

module Inferno
  module SkipHelpers
    # In the case that the user has not run the any capability statement sequences, we
    # will allow this to silently pass because we don't know if the server supports it or not.
    def skip_if_known_not_supported(resource, methods = [], operations = [])
      return if @instance.server_capabilities.nil?

      skip_if_not_supported(resource, methods, operations)
    end

    def skip_if_known_search_not_supported(resource, params)
      return if @instance.server_capabilities.nil?

      skip_if_search_not_supported(resource, params)
    end

    def skip_if_known_revinclude_not_supported(resource, revinclude)
      return if @instance.server_capabilities.nil?

      skip_if_revinclude_not_supported(resource, revinclude)
    end

    def skip_if_known_include_not_supported(resource, include)
      return if @instance.server_capabilities.nil?

      skip_if_include_not_supported(resource, include)
    end

    def skip_if_revinclude_not_supported(resource, revinclude)
      skip_unless @instance.server_capabilities.revinclude_supported?(resource, revinclude),
                  "The server doesn't support the revinclude '#{revinclude}' for the #{resource} resource"
    end

    def skip_if_include_not_supported(resource, include)
      skip_unless @instance.server_capabilities.include_supported?(resource, include),
                  "The server doesn't support the include '#{include}' for the #{resource} resource"
    end

    def skip_if_search_not_supported(resource, params)
      unsupported_search_params = params - @instance.server_capabilities.supported_search_params(resource)
      skip_unless unsupported_search_params.blank?, "The server doesn't support the search parameters: #{unsupported_search_params.join(', ')}"
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

    def skip_if_not_found(resource_type:, delayed:)
      default_message = "No #{resource_type} resources appear to be available."
      default_message += ' Please use patients with more information.' unless delayed
      skip_unless @resources_found, @skip_if_not_found_message || default_message
    end
  end
end
