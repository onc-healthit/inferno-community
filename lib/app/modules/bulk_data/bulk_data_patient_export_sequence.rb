# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkDataPatientExportSequence < SequenceBase
      group 'Bulk Data Patient Export'

      title 'Patient Tests'

      description 'Verify that Patient resources on the Bulk Data server follow the Bulk Data Access Implementation Guide'

      test_id_prefix 'Patient'

      requires :token
      conformance_supports :Patient

      def assert_export_kick_off(klass)
        reply = export_kick_off(klass)

        assert_response_accepted(reply)
        @content_location = reply.response[:headers]['content-location']

        assert @content_location.present?, 'Export response header did not include "Content-Location"'
      end

      def assert_export_kick_off_fail_invalid_accept(klass)
        reply = export_kick_off(klass, headers: { accept: 'application/fhir+xml', prefer: 'respond-async' })
        assert_response_bad(reply)
      end

      def assert_export_kick_off_fail_invalid_prefer(klass)
        reply = export_kick_off(klass, headers: { accept: 'application/fhir+json', prefer: 'return=representation' })
        assert_response_bad(reply)
      end

      def assert_export_status(url, timeout: 180)
        reply = export_status_check(url, timeout)

        skip "Server took more than #{timeout} seconds to process the request." if reply.code == 202

        assert reply.code == 200, "Bad response code: expected 200, 202, but found #{reply.code}."

        assert_response_content_type(reply, 'application/json')

        response_body = JSON.parse(reply.body)

        assert_status_reponse_required_field(response_body)

        @output = response_body['output']
      end

      def assert_file_request(output = @output)
        reply = export_file_request(output)
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
          desc %(
          )
          versions :stu3
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = export_kick_off('Patient')
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server shall return "202 Accepted" and "Content-location" for $export operation' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-kick-off-request'
          desc %(
          )
          versions :stu3
        end

        assert_export_kick_off('Patient')
      end

      test 'Server shall reject for $export operation with invalid Accept header' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#headers'
          desc %(
          )
          versions :stu3
        end

        assert_export_kick_off_fail_invalid_accept('Patient')
      end

      test 'Server shall reject for $export operation with invalid Prefer header' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#headers'
          desc %(
          )
          versions :stu3
        end

        assert_export_kick_off_fail_invalid_prefer('Patient')
      end

      test 'Server shall return "202 Accepted" or "200 OK"' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#bulk-data-status-request'
          desc %(
          )
          versions :stu3
        end

        assert_export_status(@content_location)
      end

      # test 'Server shall return file in ndjson format' do
      #   metadata do
      #     id '06'
      #     link 'https://build.fhir.org/ig/HL7/bulk-data/export/index.html#file-request'
      #     desc %(
      #     )
      #     versions :stu3
      #   end

      #   assert_file_request
      # end

      private

      def export_kick_off(klass, id: nil, headers: { accept: 'application/fhir+json', prefer: 'respond-async' })
        url = ''
        url += "/#{klass}" if klass.present?
        url += "/#{id}" if id.present?
        url += '/$export'

        @client.get(url, @client.fhir_headers(headers))
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

      def export_file_request(output)
        output.each do |item|
          reply = @client.get(url)
          binding.pry
        end
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
    end
  end
end
