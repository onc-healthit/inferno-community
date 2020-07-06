# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeCancerGenomicsReportSequence < SequenceBase
      title 'Cancer Genomics Report Tests'

      description 'Verify support for the server capabilities required by the Cancer Genomics Report.'

      details %(
      )

      test_id_prefix 'CGR'
      requires :mcode_cancer_genomics_report_id
      conformance_supports :DiagnosticReport

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct DiagnosticReport resource from the DiagnosticReport read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the DiagnosticReport with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_cancer_genomics_report_id
        read_response = validate_read_reply(FHIR::DiagnosticReport.new(id: resource_id), FHIR::DiagnosticReport)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The DiagnosticReport resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-genomics-report.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('DiagnosticReport', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-genomics-report')
      end
    end
  end
end
