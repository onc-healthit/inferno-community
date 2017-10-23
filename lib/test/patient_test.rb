module Crucible
  module App
    class Test

      def run_patient

        # Get the patient demographics
        patient = @client.read(Object.const_get("#{@klass_header}Patient"), @patient_id).resource
        @response.assert('Patient Successfully Retrieved',patient.is_a?(Object.const_get("#{@klass_header}Patient")),patient.id)
        patient_details = patient.to_hash
        puts "Patient: #{patient_details['id']} #{patient_details['name']}"

        # DAF/US-Core CCDS
        @response.assert('Patient Name',patient_details['name'],patient_details['name'])
        @response.assert('Patient Gender',patient_details['gender'],patient_details['gender'])
        @response.assert('Patient Date of Birth',patient_details['birthDate'],patient_details['birthDate'])
        # US Extensions
        puts 'Examining Patient for US-Core Extensions'
        extensions = {
          'Race' => 'http://hl7.org/fhir/StructureDefinition/us-core-race',
          'Ethnicity' => 'http://hl7.org/fhir/StructureDefinition/us-core-ethnicity',
          'Religion' => 'http://hl7.org/fhir/StructureDefinition/us-core-religion',
          'Mother\'s Maiden Name' => 'http://hl7.org/fhir/StructureDefinition/patient-mothersMaidenName',
          'Birth Place' => 'http://hl7.org/fhir/StructureDefinition/birthPlace'
        }
        required_extensions = ['Race','Ethnicity']
        extensions.each do |name,url|
          detail = nil
          check = :not_found
          if patient_details['extension']
            detail = patient_details['extension'].find{|e| e['url']==url }
            check = !detail.nil? if required_extensions.include?(name)
          elsif required_extensions.include?(name)
            check = false
          end
          @response.assert("Patient #{name}", check, detail)
        end
        @response.assert('Patient Preferred Language',(patient_details['communication'] && patient_details['communication'].find{|c|c['language'] && c['preferred']}),patient_details['communication'])

      end

    end
  end
end
