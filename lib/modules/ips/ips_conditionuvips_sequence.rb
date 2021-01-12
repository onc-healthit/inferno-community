# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsConditionuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Condition (IPS) Tests'
      description 'Verify support for the server capabilities required by the Condition (IPS) profile.'
      details %(
      )
      test_id_prefix 'CUI'
      requires :condition_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Condition resource from the Condition read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
          description %(
            This test will verify that Condition resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.condition_id
        @resource_found = validate_read_reply(FHIR::Condition.new(id: resource_id), FHIR::Condition)
        save_resource_references(versioned_resource_class('Condition'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Condition resource that matches the Condition (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
          description %(
            This test will validate that the Condition resource returned from the server matches the Condition (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Condition', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips')
      end
    end
  end
end
