# frozen_string_literal: true

require_relative 'bulk_data_group_export_sequence'

module Inferno
  module Sequence
    class OncBulkDataGroupExportSequence < BulkDataGroupExportSequence    
      extends_sequence BulkDataGroupExportSequence

      group 'ONC Bulk Data Group Export'

      title 'ONC Group Compartment Export Tests'

      description 'Verify that Group compartment export on the Bulk Data server follow ONC Health IT Certification'

      test_id_prefix 'ONC-Group'      

      def required_resources
        ['AllergyIntolerance', 'CarePlan', 'CareTeam', 'Condition', 'Device', 'DiagnosticReport', 'DocumentReference', 'Goal', 'Immunization', 'Medication', 'MedicationStatement', 'MedicatinRequest', 'Observation', 'Patient', 'Procedure']
      end

      def check_output_type(output = @saved_output)
        
        output_types = output.map{|file| file['type']}

        required_resources.each do |type|
          skip "#{type} was not in Server bulk data output" unless output_types.include?(type)
        end
      end

      test 'Server shall return FHIR resources required by ONC Health IT Certification' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/us/core/general-guidance.html'
          description %(
          )
        end
        check_output_type
      end
    end
  end
end