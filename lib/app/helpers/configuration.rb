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
          env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
        end

        def version
          VERSION
        end

        def app_name
          settings.app_name
        end

        def developer_preview
          settings.developer_preview
        end

        def valid_json?(json)
          JSON.parse(json)
          return true
        rescue JSON::ParserError => e
          return false
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

