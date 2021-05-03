# frozen_string_literal: true

Dir['lib/modules/ips/profile_definitions/*'].sort.each { |file| require './' + file }

module Inferno
  module Sequence
    class IpsSummaryOperationSequence < SequenceBase
      include Inferno::SequenceUtilities
      include IpsProfileDefinitions

      title 'Summary Operation (IPS) Tests'
      description 'Verify support for the $summary operation required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'SO'
      requires :patient_id

      def validate_bundle_entry(resource_type, profile_url)
        index = 0
        error_collection = []

        @bundle.entry.each do |entry|
          next unless entry.resource.instance_of?(resource_type)

          errors = test_resource_against_profile(entry.resource, profile_url)
          error_collection << errors.map! { |err| "Bundle.#{entry.resource.class.name.demodulize}[#{index}]: #{err}" } unless errors.empty?
          index += 1
        end

        assert(index.positive?, "Bundle does NOT have any #{resource_type.name.demodulize} entries")
        assert(error_collection.empty?, "\n* " + error_collection.join("\n* "))
      end

      def test_resource_against_profile(resource, profile_url)
        resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, profile_url)

        errors = resource_validation_errors[:errors]

        @test_warnings.concat resource_validation_errors[:warnings]
        @information_messages.concat resource_validation_errors[:information]

        errors
      end

      test :support_summay do
        metadata do
          id '01'
          link ''
          name 'IPS Server declares support for summary operation in CapabilityStatement'
          description %(
            The IPS Server SHALL declare support for Patient/[id]/$summary operation in its server CapabilityStatement
          )
        end

        @client.set_no_auth
        @conformance = @client.conformance_statement
        assert @conformance.present?, 'Cannot read server CapabilityStatement.'

        operation = nil

        @conformance.rest&.each do |rest|
          patient = rest.resource&.find { |r| r.type == 'Patient' && r.respond_to?(:operation) }

          next if patient.nil?

          # It is better to match with op.definition which is not exist at this time.
          operation = patient.operation&.find { |op| op.definition == 'http://hl7.org/fhir/OperationDefinition/Patient-summary' || ['summary', 'patient-summary'].include?(op.name.downcase) }
          break if operation.present?
        end

        assert operation.present?, 'Server CapabilityStatement did not declare support for summary operation in Patient resource.'
      end

      test :validate_bundle do
        metadata do
          id '02'
          name 'IPS Server returns Bundle resource for Patient/id/$summary operation'
          link ''
          description %(
            IPS Server return valid IPS Bundle resource as successful result of $summary operation

            POST [base]/Patient/id/$summary
          )
        end

        headers = { 'Accept' => 'application/fhir+json' }

        response = @client.post("Patient/#{@instance.patient_id}/$summary", nil, headers)

        assert_response_ok response
        assert_valid_json(response.body)
        @bundle = FHIR.from_contents(response.body)

        class_name = @bundle.class.name.demodulize
        assert class_name == 'Bundle', "Expected FHIR Bundle but found: #{class_name}"

        errors = test_resource_against_profile(@bundle, IpsBundleuvipsSequenceDefinition::PROFILE_URL)
        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      test :validate_composition do
        metadata do
          id '03'
          name 'IPS Server returns Bundle resource contains valid IPS Composition entry'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Composition-uv-ips.html'
          description %(
            IPS Server return valid IPS Composition resource in the Bundle as first entry
          )
        end

        skip 'No bundle returned from previous test' unless @bundle

        assert(@bundle.entry.length.positive?, 'Bundle has empty entry')

        entry = @bundle.entry.first

        assert(entry.resource.instance_of?(FHIR::Composition), 'The first entry in Bundle is not Composition')

        errors = test_resource_against_profile(entry.resource, IpsCompositionuvipsSequenceDefinition::PROFILE_URL)
        errors.map! { |e| "Bundle.#{entry.resource.class.name.demodulize}: #{e}" }
        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      test :validate_medication_statement do
        metadata do
          id '04'
          name 'IPS Server returns Bundle resource contains valid IPS MedicaitonStatement entry'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition-MedicationStatement-uv-ips.html'
          description %(
            IPS Server return valid IPS MedicaitonStatement resource in the Bundle as first entry
          )
        end

        skip 'No bundle returned from previous test' unless @bundle

        validate_bundle_entry(FHIR::MedicationStatement, IpsMedicationstatementipsSequenceDefinition::PROFILE_URL)
      end

      test :validate_allergy_intolerance do
        metadata do
          id '05'
          name 'IPS Server returns Bundle resource contains valid IPS AllergyIntolerance entry'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Condition-uv-ips.html'
          description %(
            IPS Server return valid IPS AllergyIntolerance resource in the Bundle as first entry
          )
        end

        skip 'No bundle returned from previous test' unless @bundle

        validate_bundle_entry(FHIR::AllergyIntolerance, IpsAllergyintoleranceuvipsSequenceDefinition::PROFILE_URL)
      end

      test :validate_condition do
        metadata do
          id '06'
          name 'IPS Server returns Bundle resource contains valid IPS Condition entry'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Condition-uv-ips.html'
          description %(
            IPS Server return valid IPS Condition resource in the Bundle as first entry
          )
        end

        skip 'No bundle returned from previous test' unless @bundle

        validate_bundle_entry(FHIR::Condition, IpsConditionuvipsSequenceDefinition::PROFILE_URL)
      end
    end
  end
end
