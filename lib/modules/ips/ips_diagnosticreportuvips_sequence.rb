# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsDiagnosticreportuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'DiagnosticReport (IPS) Tests'
      description 'Verify support for the server capabilities required by the DiagnosticReport (IPS) profile.'
      details %(
      )
      test_id_prefix 'DRUI'
      requires :diagnostic_report_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct DiagnosticReport resource from the DiagnosticReport read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
          description %(
            This test will verify that DiagnosticReport resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.diagnostic_report_id
        @resource_found = validate_read_reply(FHIR::DiagnosticReport.new(id: resource_id), FHIR::DiagnosticReport)
        save_resource_references(versioned_resource_class('DiagnosticReport'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns DiagnosticReport resource that matches the DiagnosticReport (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
          description %(
            This test will validate that the DiagnosticReport resource returned from the server matches the DiagnosticReport (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('DiagnosticReport', 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips')
      end
    end
  end
end
