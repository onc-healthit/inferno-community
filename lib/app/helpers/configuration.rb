# frozen_string_literal: true

require_relative '../utils/tls_tester'

module Inferno
  class App
    module Helpers
      module Configuration
        def base_path
          BASE_PATH
        end

        def default_scopes
          DEFAULT_SCOPES
        end

        def request_headers
          env.each_with_object({}) { |(k, v), acc| acc[Regexp.last_match(1).downcase] = v if k =~ /^http_(.*)/i; }
        end

        def version
          VERSION
        end

        def app_name
          settings.app_name
        end

        def badge_text
          settings.badge_text
        end

        def valid_json?(json)
          JSON.parse(json)
          true
        rescue JSON::ParserError => e
          false
        end

        def tls_testing_supported?
          TlsTester.testing_supported?
        end

        def show_tutorial
          settings.show_tutorial
        end
      end
    end
  end
end
