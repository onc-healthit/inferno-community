# frozen_string_literal: true

require_relative 'assertions.rb'
require 'uri'

module Inferno
  module Assertions
    def assert(test, message = 'assertion failed, no message', data = '')
      if ENV['RACK_ENV'] == 'test'
        sequence_line_regex = /inferno\/lib\/app\/modules\/(\w+\/\w+\.rb:\d+)/
        backtrace_location = caller_locations.find { |location| location.to_s.match? sequence_line_regex }
        call_site = backtrace_location&.to_s&.match(sequence_line_regex)&.[](1)
        AssertionTracker.add_assertion_call(call_site, !!test) if call_site.present?
      end
      raise AssertionException.new message, data unless test
    end

    def assert_valid_json(json)
      JSON.parse(json)
    rescue JSON::ParserError
      raise AssertionException, 'Invalid JSON'
    end

    def assert_equal(expected, actual, message = '', data = '')
      return if assertion_negated(expected == actual)

      message += " Expected: #{expected}, but found: #{actual}."
      raise AssertionException.new message, data
    end

    def assert_response_ok(response, error_message = '')
      return if assertion_negated([200, 201].include?(response.code))

      raise AssertionException, "Bad response code: expected 200, 201, but found #{response.code}. #{error_message}"
    end

    def assert_response_accepted(response)
      return if assertion_negated([202].include?(response.code))

      raise AssertionException, "Bad response code: expected 202, but found #{response.code}"
    end

    def assert_response_unauthorized(response)
      return if assertion_negated([401, 406].include?(response.code))

      raise AssertionException, "Bad response code: expected 401 or 406, but found #{response.code}"
    end

    def assert_response_bad_or_unauthorized(response)
      return if assertion_negated([400, 401].include?(response.code))

      raise AssertionException, "Bad response code: expected 400 or 401, but found #{response.code}"
    end

    def assert_response_bad(response)
      return if assertion_negated([400].include?(response.code))

      raise AssertionException, "Bad response code: expected 400, but found #{response.code}"
    end

    def assert_bundle_response(response)
      return if assertion_negated(response.resource.class == FHIR::DSTU2::Bundle || response.resource.class == FHIR::Bundle)

      # check what this is...
      found = response.resource
      begin
        found = resource_from_contents(response.body)
      rescue StandardError
        found = nil
      end
      raise AssertionException, "Expected FHIR Bundle but found: #{found.class.name.demodulize}"
    end

    def assert_response_content_type(reply, content_type)
      header = if reply.respond_to? :response # response from FHIR::Client
                 reply.response[:headers]['content-type']
               else # response from LoggedRestClient
                 reply.headers[:content_type]
               end
      response_content_type = header
      response_content_type = header[0, header.index(';')] unless header.index(';').nil?

      return if assertion_negated(response_content_type == content_type)

      raise AssertionException.new "Expected content-type #{content_type} but found #{response_content_type}", response_content_type
    end

    def assertion_negated(expression)
      @negated ? !expression : expression
    end

    def assert_tls_1_2(uri)
      tls_tester = TlsTester.new(uri: uri)

      unless uri.downcase.start_with?('https')
        raise AssertionException.new "URI is not HTTPS: #{uri}", %(

          The following URI does not use the HTTPS protocol identifier:

          [#{uri}](#{uri})

          The HTTPS protocol identifier is required for TLS connections.

          HTTP/TLS is differentiated from HTTP by using the `https`
          protocol identifier in place of the `http` protocol identifier. An
          example URI specifying HTTP/TLS is:
          `https://www.example.org`

          [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.4)


          In order to fix this error you must secure this endpoint with TLS 1.2 and ensure that references
          to this URL point to the HTTPS protocol so that use of TLS is explicit.

          You may safely ignore this error if this environment does not secure content using TLS.  If you are
          running a local copy of Inferno, you can turn off TLS detection by changing setting the `disable_tls_tests`
          option to false in `config.yml`.
          )
      end

      begin
        passed, msg, details = tls_tester.verify_ensure_tls_v1_2
        raise AssertionException.new msg, details unless passed
      rescue SocketError => e
        raise AssertionException.new "Unable to connect to #{uri}: #{e.message}", %(
            The following URI did not accept socket connections over port 443:

            [#{uri}](#{uri})

            ```
            When HTTP/TLS is being run over a TCP/IP connection, the default port
            is 443.
            ```
            [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.3)


            To fix this error ensure that the URI uses TLS.

            You may safely ignore this error if this environment does not secure content using TLS.  If you are
            running a local copy of Inferno, you can turn off TLS detection by changing setting the `disable_tls_tests`
            option to false in `config.yml`.
          )
      rescue StandardError => e
        raise AssertionException.new "Unable to connect to #{uri}: #{e.class.name}, #{e.message}", %(
            An unexpected error occurred when attempting to connect to the following URI using TLS.

            [#{uri}](#{uri})

            Ensure that this URI is protected by TLS.

            You may safely ignore this error if this environment does not secure content using TLS.  If you are
            running a local copy of Inferno, you can turn off TLS detection by changing setting the `disable_tls_tests`
            option to false in `config.yml`.
          )
      end
    end

    def assert_deny_previous_tls(uri)
      tls_tester = TlsTester.new(uri: uri)

      begin
        passed, msg, details = tls_tester.verify_deny_ssl_v3
        raise AssertionException.new msg, details unless passed

        passed, msg, details = tls_tester.verify_deny_tls_v1_1
        raise AssertionException.new msg, details unless passed

        passed, msg, details = tls_tester.verify_deny_tls_v1
        raise AssertionException.new msg, details unless passed
      rescue SocketError => e
        raise AssertionException.new "Unable to connect to #{uri}: #{e.message}", %(
            The following URI did not accept socket connections over port 443:

            [#{uri}](#{uri})

            ```
            When HTTP/TLS is being run over a TCP/IP connection, the default port
            is 443.
            ```
            [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.3)


            To fix this error ensure that the URI uses TLS.

            You may safely ignore this error if this environment does not secure content using TLS.  If you are
            running a local copy of Inferno, you can turn off TLS detection by changing setting the `disable_tls_tests`
            option to false in `config.yml`.
          )
      rescue StandardError => e
        raise AssertionException.new "Unable to connect to #{uri}: #{e.class.name}, #{e.message}", %(
            An unexpected error occured when attempting to connect to the following URI using TLS.

            [#{uri}](#{uri})

            Ensure that this URI is protected by TLS.

            You may safely ignore this error if this environment does not secure content using TLS.  If you are
            running a local copy of Inferno, you can turn off TLS detection by changing setting the `disable_tls_tests`
            option to false in `config.yml`.
          )
      end
    end

    def assert_valid_http_uri(uri, message = nil)
      error_message = message || "\"#{uri}\" is not a valid URI"
      assert (uri =~ /\A#{URI.regexp(['http', 'https'])}\z/), error_message
    end

    def assert_operation_supported(server_capabilities, op_name)
      assert server_capabilities.operation_supported?(op_name), "FHIR server capability statement did not support #{op_name} operation"
    end

    def assert_valid_conformance(conformance = @conformance)
      conformance_resource_name = versioned_conformance_class.name.demodulize
      assert(
        conformance.class == versioned_conformance_class,
        "Expected valid #{conformance_resource_name} resource."
      )
    end
  end
end
