# frozen_string_literal: true

require 'uri'

module Inferno
  module Assertions
    def assert(test, message = 'assertion failed, no message', data = '')
      if ENV['RACK_ENV'] == 'test' && create_assertion_report?
        AssertionTracker.add_assertion_call(!!test) # rubocop:disable Style/DoubleNegation
      end

      raise AssertionException.new message, data unless test
    end

    def assert_valid_json(json)
      assert JSON.parse(json)
    rescue JSON::ParserError
      assert false, 'Invalid JSON'
    end

    def assert_equal(expected, actual, message = '', data = '')
      message += " Expected: #{expected}, but found: #{actual}."
      assert expected == actual, message, data
    end

    def assert_response_ok(response, error_message = '')
      message = "Bad response code: expected 200, 201, but found #{response.code}. #{error_message}"
      assert [200, 201].include?(response.code), message
    end

    def assert_response_accepted(response)
      message = "Bad response code: expected 202, but found #{response.code}"
      assert response.code == 202, message
    end

    def assert_response_unauthorized(response)
      message = "Bad response code: expected 401, but found #{response.code}"
      assert response.code == 401, message
    end

    def assert_response_bad_or_unauthorized(response)
      message = "Bad response code: expected 400 or 401, but found #{response.code}"
      assert [400, 401].include?(response.code), message
    end

    def assert_response_bad(response)
      message = "Bad response code: expected 400, but found #{response.code}"
      assert response.code == 400, message
    end

    def assert_bundle_response(response)
      message = "Expected FHIR Bundle but found: #{resource_class(response)}"
      assert response.resource.class.name.demodulize == 'Bundle', message
    end

    def resource_class(response)
      resource =
        begin
          resource_from_contents(response.body)
        rescue StandardError
          nil
        end
      resource.class.name.demodulize
    end

    def base_header(header)
      return header unless header.include? ';'

      header[0, header.index(';')]
    end

    def header_charset(header)
      header[header.index('charset=') + 8..-1] if header.include? 'charset='
    end

    def assert_response_content_type(reply, content_type)
      header = if reply.respond_to? :response # response from FHIR::Client
                 reply.response[:headers]['content-type']
               else # response from LoggedRestClient
                 reply.headers[:content_type]
               end
      response_content_type = base_header(header)

      message = "Expected content-type #{content_type} but found #{response_content_type}"
      assert response_content_type == content_type, message, response_content_type
    end

    def assert_tls_1_2(uri)
      tls_tester = TlsTester.new(uri: uri)

      assert uri.downcase.start_with?('https'), "URI is not HTTPS: #{uri}", uri_not_https_details(uri)
      begin
        passed, message, details = tls_tester.verify_ensure_tls_v1_2
        assert passed, message, details
      rescue SocketError => e
        assert false, "Unable to connect to #{uri}: #{e.message}", tls_socket_error_details(uri)
      rescue StandardError => e
        assert false,
               "Unable to connect to #{uri}: #{e.class.name}, #{e.message}",
               tls_unexpected_error_details(uri)
      end
    end

    def assert_deny_previous_tls(uri)
      tls_tester = TlsTester.new(uri: uri)

      begin
        passed, message, details = tls_tester.verify_deny_ssl_v3
        assert passed, message, details

        passed, message, details = tls_tester.verify_deny_tls_v1_1
        assert passed, message, details

        passed, message, details = tls_tester.verify_deny_tls_v1
        assert passed, message, details
      rescue SocketError => e
        assert false, "Unable to connect to #{uri}: #{e.message}", tls_socket_error_details(uri)
      rescue StandardError => e
        assert false,
               "Unable to connect to #{uri}: #{e.class.name}, #{e.message}",
               tls_unexpected_error_details(uri)
      end
    end

    def assert_valid_http_uri(uri, message = nil)
      error_message = message || "\"#{uri}\" is not a valid URI"
      assert (uri =~ /\A#{URI.regexp(['http', 'https'])}\z/), error_message
    end

    def assert_operation_supported(server_capabilities, op_name)
      assert server_capabilities.operation_supported?(op_name),
             "FHIR server capability statement did not support #{op_name} operation"
    end

    def assert_valid_conformance(conformance = @conformance)
      conformance_resource_name = versioned_conformance_class.name.demodulize
      assert conformance.class == versioned_conformance_class,
             "Expected valid #{conformance_resource_name} resource."
    end

    def uri_not_https_details(uri)
      %(
        The following URI does not use the HTTPS protocol identifier:

        [#{uri}](#{uri})

        The HTTPS protocol identifier is required for TLS connections.

        HTTP/TLS is differentiated from HTTP by using the `https`
        protocol identifier in place of the `http` protocol identifier. An
        example URI specifying HTTP/TLS is:
        `https://www.example.org`

        [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.4)


        In order to fix this error you must secure this endpoint with TLS 1.2
        and ensure that references to this URL point to the HTTPS protocol so
        that use of TLS is explicit.
      ) + disable_tls_instructions
    end

    def tls_socket_error_details(uri)
      %(
        The following URI did not accept socket connections over port 443:

        [#{uri}](#{uri})

        ```
        When HTTP/TLS is being run over a TCP/IP connection, the default port
        is 443.
        ```
        [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.3)


        To fix this error ensure that this URI is protected by TLS.
      ) + disable_tls_instructions
    end

    def tls_unexpected_error_details(uri)
      %(
        An unexpected error occured when attempting to connect to the
        following URI using TLS.

        [#{uri}](#{uri})

        To fix this error ensure that this URI is protected by TLS.
      ) + disable_tls_instructions
    end

    def disable_tls_instructions
      %(
        You may safely ignore this error if this environment does not secure
        content using TLS. If you are running a local copy of Inferno you
        can turn off TLS detection by changing setting the
        `disable_tls_tests` option to true in `config.yml`.
      )
    end
  end
end
