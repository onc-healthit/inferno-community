# frozen_string_literal: true

require_relative './ips_shared_bundle_tests'

module Inferno
  module Sequence
    class IpsDocumentOperationSequence < SequenceBase
      include Inferno::SequenceUtilities
      include SharedIpsBundleTests

      title 'Document Operation Tests'
      description 'Verify support for the $document operation required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'DO'
      requires :composition_id

      support_operation(index: '01',
                        resource_type: 'Composition',
                        operation_name: 'document',
                        operation_definition: 'http://hl7.org/fhir/OperationDefinition/Composition-document')

      test :run_operation do
        metadata do
          id '02'
          name 'Server returns a fully bundled document from a Composition resource'
          link 'https://www.hl7.org/fhir/composition-operation-document.html'
          description %(
            This test will perform the $document operation on the chosen composition resource with the persist option on.
            It will verify that all referenced resources in the composition are in the document bundle and that we are able to retrieve the bundle after it's generated.
          )
          versions :r4
        end

        read_response = @client.read(FHIR::Composition, @instance.composition_id)
        assert_response_ok read_response
        @composition = read_response.resource

        skip 'No resource found from Read test' unless @composition.present?

        references_in_composition = []

        walk_resource(@composition) do |value, meta, _path|
          next if meta['type'] != 'Reference'
          next if value.reference.blank?

          references_in_composition << value
        end
        document_request_string = "Composition/#{@composition.id}/$document?persist=true"
        document_response = @client.get(document_request_string)

        assert_response_ok document_response
        assert_valid_json(document_response.body)
        @bundle = FHIR.from_contents(document_response.body)

        bundled_resources = @bundle.entry.map(&:resource)
        references_in_composition.each do |reference|
          next unless reference.relative? # don't know how to handle this yet

          resource_class = reference.resource_class
          resource_id = reference.reference.split('/').last
          assert(bundled_resources.any? { |resource| resource.instance_of?(resource_class) && resource.id == resource_id })
        end
      end

      resource_validate_bundle(index: '03')
      resource_validate_composition(index: '04')
      resource_validate_medication_statement(index: '05')
      resource_validate_allergy_intolerance(index: '06')
      resource_validate_condition(index: '07')
      resource_validate_device(index: '08')
      resource_validate_device_use_statement(index: '09')
      resource_validate_diagnostic_report(index: '10')
      resource_validate_immunization(index: '11')
      resource_validate_medication(index: '12')
      resource_validate_organization(index: '13')
      resource_validate_patient(index: '14')
      resource_validate_practitioner(index: '15')
      resource_validate_practitioner_role(index: '16')
      resource_validate_procedure(index: '17')
      resource_validate_observation(index: '18')
    end
  end
end
