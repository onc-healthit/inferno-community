# frozen_string_literal: true

Dir['lib/modules/uscore_v3.1.1/profile_definitions/*'].sort.each { |file| require './' + file }

module Inferno
  module Sequence
    class IpsSummaryOperationSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Document Operation Tests'
      description 'Verify support for the $document operation required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'DO'
      requires :composition_id

      test :document_operator do
        metadata do
          id '01'
          name 'Server returns a fully bundled document from a Composition resource'
          link 'https://www.hl7.org/fhir/composition-operation-document.html'
          description %(
            This test will perform the $document operation on the chosen composition resource with the persist option on.
            It will verify that all referenced resources in the composition are in the document bundle and that we are able to retrieve the bundle after it's generated.
          )
          versions :r4
        end

        response = @client.read(FHIR::Composition, @instance.composition_id)
        assert_response_ok response
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
