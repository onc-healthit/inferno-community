module Crucible
  module App
    class Test

      attr_accessor :response
      attr_accessor :url
      attr_accessor :token
      attr_accessor :patient_id
      attr_accessor :scopes
      attr_accessor :client
      attr_accessor :version
      attr_accessor :klass_header
      attr_accessor :conformance_klass
      attr_accessor :supporting_resources
      attr_accessor :vital_signs
      attr_accessor :accessible_resources
      attr_accessor :conformance
      attr_accessor :readable_resource_names

      def initialize(url, token_params, response)
        @url = url
        @response = response

        @response.start_table('Crucible Test Results',['Status','Description','Detail'])

        # Get token, patient id, and scopes for testing
        @token = token_params['access_token']
        @patient_id = token_params['patient']
        @scopes = token_params['scope']
        if @scopes.nil?
          @scopes = Crucible::App::Config.get_scopes(url)
        end

        # Configure the FHIR Client
        @client = FHIR::Client.new(url)
        @version = @client.detect_version
        @client.set_bearer_token(@token)
        @client.default_json

        # All supporting resources
        if @version == :dstu2
          @klass_header = "FHIR::DSTU2::"
          @conformance_klass = FHIR::DSTU2::Conformance
          @supporting_resources = [
            FHIR::DSTU2::AllergyIntolerance, FHIR::DSTU2::CarePlan, FHIR::DSTU2::Condition,
            FHIR::DSTU2::DiagnosticOrder, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Encounter,
            FHIR::DSTU2::FamilyMemberHistory, FHIR::DSTU2::Goal, FHIR::DSTU2::Immunization,
            FHIR::DSTU2::List, FHIR::DSTU2::Procedure, FHIR::DSTU2::MedicationAdministration,
            FHIR::DSTU2::MedicationDispense, FHIR::DSTU2::MedicationOrder,
            FHIR::DSTU2::MedicationStatement, FHIR::DSTU2::Observation, FHIR::DSTU2::RelatedPerson
          ]
          # Vital Signs includes these codes as defined in http://loinc.org
          @vital_signs = {
            '9279-1' => 'Respiratory rate',
            '8867-4' => 'Heart rate',
            '2710-2' => 'Oxygen saturation in Capillary blood by Oximetry',
            '55284-4' => 'Blood pressure systolic and diastolic',
            '8480-6' => 'Systolic blood pressure',
            '8462-4' => 'Diastolic blood pressure',
            '8310-5' => 'Body temperature',
            '8302-2' => 'Body height',
            '8306-3' => 'Body height --lying',
            '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
            '3141-9' => 'Body weight Measured',
            '39156-5' => 'Body mass index (BMI) [Ratio]',
            '3140-1' => 'Body surface area Derived from formula',
            '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
            '8478-0' => 'Mean blood pressure'
          }
        elsif @version == :stu3
          @klass_header = "FHIR::"
          @conformance_klass = FHIR::CapabilityStatement
          @supporting_resources = [
            FHIR::AllergyIntolerance, FHIR::CarePlan, FHIR::CareTeam, FHIR::Condition, FHIR::Device,
            FHIR::DiagnosticReport, FHIR::Goal, FHIR::Immunization, FHIR::MedicationRequest,
            FHIR::MedicationStatement, FHIR::Observation, FHIR::Procedure, FHIR::RelatedPerson, FHIR::Specimen
          ]
          # Vital Signs includes these codes as defined in http://hl7.org/fhir/STU3/observation-vitalsigns.html
          @vital_signs = {
            '85353-1' => 'Vital signs, weight, height, head circumference, oxygen saturation and BMI panel',
            '9279-1' => 'Respiratory Rate',
            '8867-4' => 'Heart rate',
            '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
            '8310-5' => 'Body temperature',
            '8302-2' => 'Body height',
            '8306-3' => 'Body height --lying',
            '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
            '29463-7' => 'Body weight',
            '39156-5' => 'Body mass index (BMI) [Ratio]',
            '85354-9' => 'Blood pressure systolic and diastolic',
            '8480-6' => 'Systolic blood pressure',
            '8462-4' => 'Diastolic blood pressure'
          }
        end

        # Parse accessible resources from scopes
        accessible_resource_names = @scopes.scan(/patient\/(.*?)\.[read|\*]/)
        @accessible_resources = []
        if accessible_resource_names.include?(["*"])
          @accessible_resources = @supporting_resources.dup
        else
          @accessible_resources = accessible_resource_names.map {|w| Object.const_get("#{@klass_header}#{w.first}")}
        end

        # Get the conformance statement
        @conformance = @client.conformance_statement
        conformance_details = @conformance.to_hash

        puts "FHIR Version: #{conformance_details['fhirVersion']}"

        # Get read capabilities
        @readable_resource_names = []
        @readable_resource_names = conformance_details['rest'][0]['resource'].select {|r|
          r['interaction'].include?({"code"=>"read"})
        }.map {|n| n['type']}

      end

      def score

        # Output a summary
        total = @response.pass + @response.not_found + @response.skip + @response.fail
        @response.assert("#{((@response.pass.to_f / total.to_f)*100.0).round}% (#{@response.pass} of #{total})",true,'Total tests passed')
        @response.assert("#{((@response.not_found.to_f / total.to_f)*100.0).round}% (#{@response.not_found} of #{total})",:not_found,'Total tests "not found" or inconclusive')
        @response.assert("#{((@response.skip.to_f / total.to_f)*100.0).round}% (#{@response.skip} of #{total})",:skip,'Total tests skipped')
        @response.assert("#{((@response.fail.to_f / total.to_f)*100.0).round}% (#{@response.fail} of #{total})",false,'Total tests failed')
        @response.end_table

      end

    end
  end
end
