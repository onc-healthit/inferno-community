# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsSummaryOperationSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Summary Operation (IPS) Tests'
      description 'Verify support for the $summary operation required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'SO'
      requires :patient_id

      

      def validate_response(response)
        assert_response_ok response
        assert_valid_json(response.body)
        @bundle = FHIR.from_contents(response.body)
      end

      def assert_bundle_valid(bundle)

      end

      test 'IPS Server declares support for summary operation in CapabilityStatement' do
        metadata do
          id '01'
          link ''
          description %(
            The IPS Server SHALL declare support for Patient/[id]/$summary operation in its server CapabilityStatement
          )
        end

        @client.set_no_auth
        @conformance = @client.conformance_statement
        assert conformance.present?, 'Cannot read server CapabilityStatement.'

        operation = nil

        conformance.rest&.each do |rest|
          patient = rest.resource&.find { |r| r.type == 'Patient' && r.respond_to?(:operation) }

          next if patient.nil?

          # It is better to match with op.definition which is not exist at this time. 
          patient = patient.operation&.find { |op| op.definition == 'http://hl7.org/fhir/OperationDefinition/Patient-summary' || ['summary', 'patient-summary'].include?(op.name.downcase)}
          break if operation.present?
        end

        assert operation.present?, 'Server CapabilityStatement did not declare support for summary operation in Patient resource.'
      end

      test 'IPS Server returns Bundle resource for Patient/id/$summary operation' do
        metadata do
          id '02'
          link ''
          description %(
            IPS Server return valid IPS Bundle resource as successful result of $summary operation

            POST [base]/Patient/id/$summary
          )
        end

        response = @client.post("Patient/#{@instance.patient_id}/$summary")

        bundle = validate_response(response)
      end
    end
  end
end