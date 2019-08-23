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

      @content_location = nil

      # export
      def export_kick_off(klass)
        headers = { accept: 'application/fhir+json', prefer: 'respond-async' }

        url = "/#{klass}/$export"

        reply = @client.get(url, @client.fhir_headers(headers))
        reply
      end

      details %(

        The #{title} Sequence tests `#{title}` operations.  The operation steps will be checked for consistency against the
        [Bulk Data Access Implementation Guide](https://build.fhir.org/ig/HL7/bulk-data/)

      )

      @resources_found = false

      test 'Server rejects Patient search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :stu3
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        @client.set_bearer_token(@instance.token)
      end

      test 'Server shall return "202 Accepted" and "Cotent-location" for $export operation' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :stu3
        end

        reply = export_kick_off('Patient')

        # Shall return 202
        assert_response_accepted(reply)

        @content_location = reply.response[:headers]['content-location']

        # Shall have Content-location
        assert @content_location.present?, 'Server must include Cotent-Location header for $export request'
      end
    end
  end
end
