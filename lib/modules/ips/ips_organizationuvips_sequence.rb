# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsOrganizationuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Organization (IPS) Tests'
      description 'Verify support for the server capabilities required by the Organization (IPS) profile.'
      details %(
      )
      test_id_prefix 'OUI'
      requires :organization_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Organization resource from the Organization read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'
          description %(
            This test will verify that Organization resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.organization_id
        @resource_found = validate_read_reply(FHIR::Organization.new(id: resource_id), FHIR::Organization)
        save_resource_references(versioned_resource_class('Organization'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Organization resource that matches the Organization (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'
          description %(
            This test will validate that the Organization resource returned from the server matches the Organization (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Organization', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips')
      end
    end
  end
end
