# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsCompositionuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Composition (IPS) Tests'
      description 'Verify support for the server capabilities required by the Composition (IPS) profile.'
      details %(
      )
      test_id_prefix 'CUI'
      requires :composition_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Composition resource from the Composition read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          description %(
            This test will verify that Composition resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.composition_id
        @resource_found = validate_read_reply(FHIR::Composition.new(id: resource_id), FHIR::Composition)
        save_resource_references(versioned_resource_class('Composition'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Composition resource that matches the Composition (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          description %(
            This test will validate that the Composition resource returned from the server matches the Composition (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Composition', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end

      test :document_operator do
        metadata do
          id '03'
          name 'Server returns a fully bundled document from a Composition resource'
          link 'https://www.hl7.org/fhir/composition-operation-document.html'
          description %(
            This test will perform the $document operation on the chosen composition resource with the persist option on.
            It will verify that all referenced resources in the composition are in the document bundle and that we are able to retrieve the bundle after it's generated.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        references_in_composition = []
        walk_resource(@resource_found) do |value, meta, _path|
          next if meta['type'] != 'Reference'
          next if value.reference.blank?

          references_in_composition << value
        end
        document_request_string = "Composition/#{@resource_found.id}/$document?persist=true"
        document_response = @client.get(document_request_string)

        assert_response_ok document_response
        assert_valid_json(document_response.body)
        bundle = FHIR.from_contents(document_response.body)

        bundled_resources = bundle.entry.map(&:resource)
        references_in_composition.each do |reference|
          next unless reference.relative? # don't know how to handle this yet

          resource_class = reference.resource_class
          resource_id = reference.reference.split('/').last
          assert(bundled_resources.any? { |resource| resource.class == resource_class && resource.id == resource_id })
        end
      end
    end
  end
end
