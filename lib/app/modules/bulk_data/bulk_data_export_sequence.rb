# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataExportSequence < SequenceBase
      group 'Bulk Data Export'

      title 'Bulk Data Export Tests'

      description 'Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'BulkData'

      requires :token

      attr_accessor :run_all_kick_off_tests

      def endpoint
        nil
      end

      def resource_id
        nil
      end

      def type_parameter
        endpoint
      end

      def save_output?
        false
      end

      def check_export_kick_off(search_params: nil)
        @search_params = search_params
        reply = export_kick_off(endpoint, resource_id, search_params: search_params)
        @server_supports_type_parameter = search_params&.key?('_type')

        # Servers unable to support _type SHOULD return an error and OperationOutcome resource
        # so clients can re-submit a request omitting the _type parameter.
        if @server_supports_type_parameter && is_4xx_error?(reply)
          @server_supports_type_parameter = false
          skip 'Server does not support _type operation parameter'
        end

        assert_response_accepted(reply)
        @content_location = reply.response[:headers]['content-location']

        assert @content_location.present?, 'Export response header did not include "Content-Location"'
      end

      def check_export_kick_off_fail_invalid_accept
        reply = export_kick_off(endpoint, resource_id, headers: { accept: 'application/fhir+xml', prefer: 'respond-async' })
        assert_response_bad(reply)
      end

      def check_export_kick_off_fail_invalid_prefer
        reply = export_kick_off(endpoint, resource_id, headers: { accept: 'application/fhir+json', prefer: 'return=representation' })
        assert_response_bad(reply)
      end

      def check_export_kick_off_fail_invalid_parameter(search_params)
        reply = export_kick_off(endpoint, resource_id, search_params: search_params)
        assert_response_bad(reply)
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

      def assert_output_has_correct_type(output = @output,
                                         search_params = @search_params)
        assert output.present?, 'Sever response did not have output data'

        search_type = search_params['_type'].split(',').map(&:strip) if search_params&.key?('_type')

        output.each do |file|
          assert search_type.include?(file['type']), "Output file had type #{file['type']} not specified in export parameter #{search_params['_type']}" if search_type.present?
        end
      end

      def check_file_request(output = @output, index: 0)
        skip 'Sever response did not have output data' unless output.present?

        file = output[index]

        headers = { accept: 'application/fhir+ndjson' }
        url = file['url']
        type = file['type']
        reply = @client.get(url, @client.fhir_headers(headers))
        assert_response_content_type(reply, 'application/fhir+ndjson')

        check_ndjson(reply.body, type)
      end

      def check_ndjson(ndjson, type)
        ndjson.each_line do |line|
          resource = FHIR.from_contents(line)
          assert resource.class.name.demodulize == type, "Resource in output file did not have type of \"#{type}\""
          errors = resource.validate
          assert errors.empty?, errors.to_s
        end
      end

      def check_delete_request
        reply = delete_export
        skip 'Server did not accept client request to delete export file after export completed' if is_4xx_error?(reply)
        assert_response_accepted(reply)
      end

      def check_cancel_request
        @content_location = nil
        check_export_kick_off
        check_delete_request
      end

      def delete_export(url = @content_location)
        @client.delete(url, {})
      end

      details %(

      The #{title} Sequence tests `#{title}` operations.  The operation steps will be checked for consistency against the
      [Bulk Data Access Implementation Guide](https://build.fhir.org/ig/HL7/bulk-data/)

      )

      @resources_found = false

      test 'Server rejects $export request without authorization' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-kick-off-request'
          description %(
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = export_kick_off(endpoint, resource_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server shall return "202 Accepted" and "Content-location" for $export operation' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-kick-off-request'
          description %(
          )
        end

        check_export_kick_off
      end

      test 'Server shall reject for $export operation with invalid Accept header' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#headers'
          description %(
          )
        end

        check_export_kick_off_fail_invalid_accept
      end

      test 'Server shall reject for $export operation with invalid Prefer header' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#headers'
          description %(
          )
        end

        check_export_kick_off_fail_invalid_prefer
      end

      test 'Server shall return "202 Accepted" or "200 OK" for status check' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-status-request'
          description %(
          )
        end

        check_export_status
      end

      test 'Completed Status Check shall return output with type and url' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-status-request'
          description %(
          )
        end

        assert_output_has_type_url
      end

      test 'Server shall return FHIR resources in ndjson file' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#file-request'
          description %(
          )
        end

        check_file_request
      end

      test 'Server shall return "202 Accepted" for delete export request' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-delete-request'
          description %(
          )
          optional
        end

        check_delete_request
      end

      test 'Server shall return "202 Accepted" for cancel export request' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-delete-request'
          description %(
          )
          optional
        end

        check_cancel_request
      end

      test 'Server shall return "202 Accepted" and "Content-location" for $export operation with _type parameters' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#query-parameters'
          description %(
          )
          optional
        end

        check_export_kick_off(search_params: { '_type' => type_parameter })
      end

      test 'Server shall return FHIR resources required by _type filter' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#file-request'
          description %(
          )
          optional
        end

        skip 'Server does not support _type parameter' unless @server_supports_type_parameter

        check_export_status
        assert_output_has_correct_type
        delete_export
      end

      test 'Server shall reject $export operation with invalid _type parameters' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#file-request'
          description %(
          )
          optional
        end

        check_export_kick_off_fail_invalid_parameter('_type' => 'UnknownResource')
      end

      private

      def export_kick_off(endpoint,
                          id = nil,
                          search_params: nil,
                          headers: { accept: 'application/fhir+json', prefer: 'respond-async' })
        url = ''
        url += "/#{endpoint}" if endpoint.present?
        url += "/#{id}" if endpoint.present? && id.present?
        url += '/$export'

        uri = Addressable::URI.parse(url)
        uri.query_values = search_params if search_params.present?
        full_url = uri.to_s

        @client.get(full_url, @client.fhir_headers(headers))
      end

      def export_status_check(url, timeout)
        wait_time = 1
        reply = nil
        headers = { accept: 'application/json' }
        start = Time.now

        loop do
          reply = @client.get(url, @client.fhir_headers(headers))

          wait_time = get_wait_time(wait_time, reply)
          seconds_used = Time.now - start + wait_time

          break if reply.code != 202 || seconds_used > timeout

          sleep wait_time
        end

        reply
      end

      def get_wait_time(wait_time, reply)
        retry_after = reply.response[:headers]['retry-after']
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

      def is_4xx_error?(response)
        response.code >= 400 && response.code < 500
      end
    end
  end
end
