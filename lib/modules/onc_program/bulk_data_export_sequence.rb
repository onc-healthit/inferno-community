# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataExportSequence < SequenceBase
      group 'Bulk Data Export'

      title 'Bulk Data Export Tests'

      description 'Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'BDE'

      requires :bulk_url, :bulk_access_token, :bulk_lines_to_validate

      attr_accessor :run_all_kick_off_tests

      def endpoint
        nil
      end

      def resource_id
        nil
      end

      def type_parameter
        'Patient'
      end

      def check_capability_statement
        if @instance.bulk_url.present?
          url = @instance.bulk_url
          url = url.chop if url.end_with?('/')
        else
          url = ''
        end

        url += '/metadata'
        headers = { accept: 'application/fhir+json' }
        reply = LoggedRestClient.get(url, headers)
        assert_response_ok(reply)

        conformance = versioned_resource_class.from_contents(reply.body)
        assert conformance.present?, 'Cannot read server CapabilityStatement.'

        operation = nil

        conformance.rest&.each do |rest|
          group = rest.resource&.find { |r| r.type == 'Group' && r.respond_to?(:operation) }

          next if group.nil?

          operation = group.operation&.find { |op| op.definition == 'http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export' }
          break if operation.present?
        end

        assert operation.present?, 'Server CapabilityStatement did not declare support for export operation in Group resource.'
      end

      def check_export_kick_off
        reply = export_kick_off(endpoint, resource_id)

        assert_response_accepted(reply)
        @content_location = reply.headers[:content_location]

        assert @content_location.present?, 'Export response header did not include "Content-Location"'
      end

      def check_export_kick_off_fail_invalid_accept
        reply = export_kick_off(endpoint, resource_id, headers: { accept: 'application/fhir+xml', prefer: 'respond-async' })
        assert_kick_off_error_response(reply)
      end

      def check_export_kick_off_fail_invalid_prefer
        reply = export_kick_off(endpoint, resource_id, headers: { accept: 'application/fhir+json', prefer: 'return=representation' })
        assert_kick_off_error_response(reply)
      end

      def assert_kick_off_error_response(reply)
        assert reply.code >= 400, "Bad response code: expected 4xx or 5xx, but found #{reply.code}"
        assert_response_content_type(reply, 'application/json')

        resource = versioned_resource_class.from_contents(reply.body)
        resource_type = resource.class.name.demodulize
        assert resource_type == 'OperationOutcome', "Bad response body. Expected OperationOutcome but received #{resource_type}"
      end

      def check_export_status(url = @content_location, timeout: 180)
        skip 'Server response did not have Content-Location in header' unless url.present?
        reply = export_status_check(url, timeout)

        # server response status code could be 202 (still processing), 200 (complete) or 4xx/5xx error code
        # export_status_check processes reponses with status 202 code
        # and returns server response when status code is not 202 or timed out

        skip "Server took more than #{timeout} seconds to process the request." if reply.code == 202

        assert reply.code == 200, "Bad response code: expected 200, 202, but found #{reply.code}."

        assert_response_content_type(reply, 'application/json')

        response_body = JSON.parse(reply.body)

        assert_status_reponse_required_field(response_body)

        @status_response = response_body
        @output = response_body['output']
      end

      def assert_output_has_type_url(output = @output)
        assert output.present?, 'Sever response did not have output data'

        output.each do |file|
          ['type', 'url'].each do |key|
            assert file.key?(key), "Output file did not contain \"#{key}\" as required"
          end
        end
      end

      def assert_requires_access_token(status_response = @status_response)
        omit 'Require Access Token Test has been disabled by configuration.' if @instance.disable_bulk_data_require_access_token_test

        assert status_response.present?, 'Bulk Data server response is empty'
        requires_access_token = status_response['requiresAccessToken']
        assert requires_access_token.present? && requires_access_token.to_s.downcase == 'true', 'Bulk Data file server access SHALL require access token.'
      end

      details %(

      The #{title} Sequence tests `#{title}` operations.  The operation steps will be checked for consistency against the
      [Bulk Data Access Implementation Guide](https://build.fhir.org/ig/HL7/bulk-data/)

      )

      @resources_found = false

      test :bulk_endpoint_tls do
        metadata do
          id '01'
          name 'Bulk Data Server is secured by transport layer security'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'
          description %(
            All exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246)
          )
        end

        omit_if_tls_disabled

        assert_tls_1_2 @instance.bulk_url
        assert_deny_previous_tls @instance.bulk_url
      end

      test 'Bulk Data Server declares support for Group export operation in CapabilityStatement' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/uv/bulkdata/OperationDefinition-group-export.html'
          description %(
            The Bulk Data Server SHALL declare support for Group/[id]/$export operation in its server CapabilityStatement
          )
        end

        check_capability_statement
      end

      test 'Bulk Data Server rejects $export request without authorization' do
        metadata do
          id '03'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#bulk-data-kick-off-request'
          description %(
            The FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized.

            [FHIR R4 Security](http://build.fhir.org/security.html#AccessDenied) and
            [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
            recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy and context.
          )
        end

        skip 'Could not verify this functionality when bearer token is not set' if @instance.bulk_access_token.blank?

        reply = export_kick_off(endpoint, resource_id, use_token: false)
        assert_response_bad_or_unauthorized(reply)
      end

      test 'Bulk Data Server rejects $export operation with invalid Accept header' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#headers'
          description %(
            Accept (string, required)

            * Specifies the format of the optional OperationOutcome resource response to the kick-off request. Currently, only application/fhir+json is supported.
          )
        end

        check_export_kick_off_fail_invalid_accept
      end

      test 'Bulk Data Server rejects $export operation with invalid Prefer header' do
        metadata do
          id '05'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#headers'
          description %(
            Prefer (string, required)

            * Specifies whether the response is immediate or asynchronous. The header SHALL be set to respond-async https://tools.ietf.org/html/rfc7240.
          )
        end

        check_export_kick_off_fail_invalid_prefer
      end

      test 'Bulk Data Server returns "202 Accepted" and "Content-location" for $export operation' do
        metadata do
          id '06'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#response---success'
          description %(
            Response - Success

            * HTTP Status Code of 202 Accepted
            * Content-Location header with the absolute URL of an endpoint for subsequent status requests (polling location)
          )
        end

        check_export_kick_off
      end

      test 'Bulk Data Server returns "202 Accepted" or "200 OK" for status check' do
        metadata do
          id '07'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#bulk-data-status-request'
          description %(
            Clients SHOULD follow an exponential backoff approach when polling for status. Servers SHOULD respond with

            * In-Progress Status: HTTP Status Code of 202 Accepted
            * Complete Status: HTTP status of 200 OK and Content-Type header of application/json

            The JSON object of Complete Status SHALL contain these required field:

            * transactionTime, request, requiresAccessToken, output, and error
          )
        end

        check_export_status
      end

      test 'Bulk Data Server returns output with type and url for status complete' do
        metadata do
          id '08'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#response---complete-status'
          description %(
            The value of output field is an array of file items with one entry for each generated file.
            If no resources are returned from the kick-off request, the server SHOULD return an empty array.

            Each file item SHALL contain the following fields:

            * type - the FHIR resource type that is contained in the file.

            Each file SHALL contain resources of only one type, but a server MAY create more than one file for each resource type returned.

            * url - the path to the file. The format of the file SHOULD reflect that requested in the _outputFormat parameter of the initial kick-off request.
         )
        end

        assert_output_has_type_url
        @instance.bulk_status_output = @status_response.to_json
      end

      test 'Bulk Data Server returns requiresAccessToken with value true' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#response---complete-status'
          description %(
            Bulk Data Server SHALL restrict bulk data file access with access token
         )
        end

        assert_requires_access_token
      end

      test :bulk_data_delete_test do
        metadata do
          id '10'
          name 'Bulk Data Server returns "202 Accepted" for delete request'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#bulk-data-delete-request'
          description %(
            After a bulk data request has been started, a client MAY send a delete request to the URL provided in the Content-Location header to cancel the request.
            Bulk Data Server MUST support client's delete request and return HTTP Status Code of "202 Accepted"
         )
        end

        reply = export_kick_off(endpoint, resource_id)

        assert_response_accepted(reply)

        content_location = reply.headers[:content_location]

        assert content_location.present?, 'Export response header did not include "Content-Location"'

        reply = LoggedRestClient.delete(content_location, build_header({ accept: 'application/json' }))

        assert_response_accepted(reply)
      end

      private

      def export_kick_off(endpoint,
                          id = nil,
                          search_params: nil,
                          headers: { accept: 'application/fhir+json', prefer: 'respond-async' },
                          use_token: true)
        if @instance.bulk_url.present?
          url = @instance.bulk_url
          url = url.chop if url.end_with?('/')
        else
          url = ''
        end

        url += "/#{endpoint}" if endpoint.present?
        url += "/#{id}" if endpoint.present? && id.present?
        url += '/$export'

        uri = Addressable::URI.parse(url)
        uri.query_values = search_params if search_params.present?
        full_url = uri.to_s

        LoggedRestClient.get(full_url, build_header(headers, use_token: use_token))
      end

      def export_status_check(url, timeout)
        wait_time = 1
        reply = nil
        headers = { accept: 'application/json' }
        start = Time.now

        loop do
          reply = LoggedRestClient.get(url, build_header(headers))

          wait_time = get_wait_time(wait_time, reply)
          seconds_used = Time.now - start + wait_time

          break if reply.code != 202 || seconds_used > timeout

          sleep wait_time
        end

        reply
      end

      def get_wait_time(wait_time, reply)
        retry_after = reply.headers[:retry_after]
        retry_after_int = (retry_after.presence || 0).to_i

        if retry_after_int.positive?
          retry_after_int
        else
          wait_time * 2
        end
      end

      def assert_status_reponse_required_field(response_body)
        ['transactionTime', 'request', 'requiresAccessToken', 'output', 'error'].each do |key|
          assert response_body.key?(key), "Complete Status response did not contain \"#{key}\" as required"
        end
      end

      def build_header(headers, use_token: true)
        headers['Authorization'] = 'Bearer ' + @instance.bulk_access_token if use_token && @instance.bulk_access_token.present?
        headers
      end
    end
  end
end
