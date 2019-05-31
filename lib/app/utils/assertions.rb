# frozen_string_literal: true

require_relative 'assertions.rb'
module Inferno
  module Assertions
    def assert(test, message = 'assertion failed, no message', data = '')
      raise AssertionException.new message, data unless test
    end

    def assert_equal(expected, actual, message = '', data = '')
      unless assertion_negated(expected == actual)
        message += " Expected: #{expected}, but found: #{actual}."
        raise AssertionException.new message, data
      end
    end

    def assert_response_ok(response, error_message = '')
      unless assertion_negated([200, 201].include?(response.code))
        raise AssertionException, "Bad response code: expected 200, 201, but found #{response.code}.#{' ' + error_message}" # ,response.body
      end
    end

    def assert_response_not_found(response)
      unless assertion_negated([404].include?(response.code))
        raise AssertionException, "Bad response code: expected 404, but found #{response.code}" # ,response.body
      end
    end

    def assert_response_unauthorized(response)
      unless assertion_negated([401, 406].include?(response.code))
        raise AssertionException, "Bad response code: expected 401 or 406, but found #{response.code}" # ,response.body
      end
    end

    def assert_response_bad_or_unauthorized(response)
      unless assertion_negated([400, 401].include?(response.code))
        raise AssertionException, "Bad response code: expected 400 or 401, but found #{response.code}" # ,response.body
      end
    end

    def assert_response_bad(response)
      unless assertion_negated([400].include?(response.code))
        raise AssertionException, "Bad response code: expected 400, but found #{response.code}" # ,response.body
      end
    end

    def assert_response_conflict(response)
      unless assertion_negated([409, 412].include?(response.code))
        raise AssertionException, "Bad response code: expected 409 or 412, but found #{response.code}" # ,response.body
      end
    end

    def assert_navigation_links(bundle)
      unless assertion_negated(bundle.first_link && bundle.last_link && bundle.next_link)
        raise AssertionException, 'Expecting first, next and last link to be present'
      end
    end

    def assert_bundle_response(response)
      unless assertion_negated(response.resource.class == FHIR::DSTU2::Bundle || response.resource.class == FHIR::Bundle)
        # check what this is...
        found = response.resource
        begin
          found = resource_from_contents(response.body)
        rescue StandardError
          found = nil
        end
        raise AssertionException, "Expected FHIR Bundle but found: #{found.class.name.demodulize}" # ,response.body
      end
    end

    def assert_bundle_transactions_okay(response)
      response.resource.entry.each do |entry|
        unless assertion_negated(!entry.response.nil?)
          raise AssertionException, 'All Transaction/Batch Bundle.entry elements SHALL have a response.'
        end

        status = entry.response.status
        unless assertion_negated(status && status.start_with?('200', '201', '204'))
          raise AssertionException, "Expected all Bundle.entry.response.status to be 200, 201, or 204; but found: #{status}"
        end
      end
    end

    def assert_resource_content_type(client_reply, content_type)
      header = client_reply.response[:headers]['content-type']
      response_content_type = header
      response_content_type = header[0, header.index(';')] unless header.index(';').nil?

      unless assertion_negated(response_content_type == "application/fhir+#{content_type}")
        raise AssertionException.new "Expected content-type application/fhir+#{content_type} but found #{response_content_type}", response_content_type
      end
    end

    # Based on MIME Types defined in
    # http://hl7.org/fhir/2015May/http.html#2.1.0.6
    def assert_valid_resource_content_type_present(client_reply)
      header = client_reply.response[:headers]['content-type']
      content_type = header
      charset = encoding = nil

      content_type = header[0, header.index(';')] unless header.index(';').nil?
      charset = header[header.index('charset=') + 8..-1] unless header.index('charset=').nil?
      encoding = Encoding.find(charset) unless charset.nil?

      unless assertion_negated(encoding == Encoding::UTF_8)
        raise AssertionException.new "Response content-type specifies encoding other than UTF-8: #{charset}", header
      end
      unless assertion_negated((content_type == FHIR::Formats::ResourceFormat::RESOURCE_XML) || (content_type == FHIR::Formats::ResourceFormat::RESOURCE_JSON))
        raise AssertionException.new "Invalid FHIR content-type: #{content_type}", header
      end
    end

    def assert_etag_present(client_reply)
      header = client_reply.response[:headers]['etag']
      assert assertion_negated(!header.nil?), 'ETag HTTP header is missing.'
    end

    def assert_last_modified_present(client_reply)
      header = client_reply.response[:headers]['last-modified']
      assert assertion_negated(!header.nil?), 'Last-modified HTTP header is missing.'
    end

    def assert_valid_content_location_present(client_reply)
      header = client_reply.response[:headers]['location']
      assert assertion_negated(!header.nil?), 'Location HTTP header is missing.'
    end

    def assert_response_code(response, code)
      unless assertion_negated(code.to_s == response.code.to_s)
        raise AssertionException, "Bad response code: expected #{code}, but found #{response.code}" # ,response.body
      end
    end

    def assert_resource_type(response, resource_type)
      unless assertion_negated(!response.resource.nil? && response.resource.class == resource_type)
        raise AssertionException, "Bad response type: expected #{resource_type}, but found #{response.resource.class}." # ,response.body
      end
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
  end
end
