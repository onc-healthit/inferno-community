# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4ClinicalNotesSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Clinical Notes Guideline Tests'

      description 'Verify that DocumentReference and DiagnosticReport resources on the FHIR server follow the US Core R4 Clinical Notes Guideline'

      test_id_prefix 'ClinicalNotes' # change me

      requires :token, :patient_id
      conformance_supports :DocumentReference


      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Documentreference Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-documentreference)

      )

      @clinicalnotes_found = false

      def test_clinicalnotes_documentreference(type_code)
        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinicalnotes_found

        assert @must_have_type_code[type_code], "Clinical Notes shall have at least one DocumentReference with type #{type_code}"
      end

      def test_clinicalnotes_diagnosticreport(category_code)
        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinicalnotes_found

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val, 'category': category_code }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        assert @resources_found, "Clinical Notes shall have at least one DiagnosticReport with category #{category_code}"

        diagnosticreport_ary = reply&.resource&.entry&.map { |entry| entry&.resource }

        diagnosticreport_ary&.each do |resource|
          id = resource&.id

          resource&.presentedForm&.each do |attachment|
            url_value = attachment&.url
            next if url_value.nil?
            
            assert @attachment_url.key?(url_value), "Attachment #{url_value} referenced in DiagnosticReport/#{id} but not in any DocumentReference"
            @attachment_url[url_value][:flag] = true
          end 
        end

      end

      test 'Server returns expected results from DocumentReference search by patient+clinicalnotes' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        category_val = 'clinical-note'
        search_params = { 'patient': patient_val, 'category': category_val }
        @attachment_url = {}

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)        
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @clinicalnotes_found = true if resource_count.positive?

        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinicalnotes_found

        documentreference_ary = reply&.resource&.entry&.map { |entry| entry&.resource }

        @must_have_type_code = {
          "11488-4" => false, #Consultation Note
          "18842-5" => false, #Dischard Summary
          "34117-2" => false, #History and physical note
          "28570-0" => false, #Procedure note
          "11506-3" => false #Progress note
        }

        documentreference_ary&.each do |resource|
          codings = resource&.type&.coding
          next if codings.nil?

          codings&.each do |coding|
            code = coding&.code
            system = coding&.system

            next if system != 'http://loinc.org' or  !@must_have_type_code.key?(code)

            @must_have_type_code[code] = true

            resource&.content&.each do |a_content|
              url_value = a_content&.attachment&.url
              next if url_value.nil? or @attachment_url.key?(url_value)

              @attachment_url[url_value] = {id: resource&.id, flag: false}
            end
          end
        end

        #must_have_type_code.each {|key, value| assert value, "Could not find DocumentReference having type #{key}"}
      end

      test 'Server shall have Consultation Notes' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinicalnotes_documentreference("11488-4")
      end

      test 'Server shall have Discharge Summary' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinicalnotes_documentreference("18842-5")
      end

      test 'Server shall have History and Physical Note' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinicalnotes_documentreference("34117-2")
      end

      test 'Server shall have Procedures Note' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinicalnotes_documentreference("28570-0")
      end

      test 'Server shall have Progress Note' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinicalnotes_documentreference("11506-3")
      end

      test 'Server returns Cardiology report from DiagnosticReport search by patient+category' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinicalnotes_diagnosticreport('http://loinc.org|LP29708-2')
      end

      test 'Server returns Pathology report from DiagnosticReport search by patient+category' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end     
        
        test_clinicalnotes_diagnosticreport('http://loinc.org|LP7839-6')
      end

      test 'Server returns Radiology report from DiagnosticReport search by patient+category' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end     
        
        test_clinicalnotes_diagnosticreport('http://loinc.org|LP29684-5')
      end

      test 'DiagnosticReport and DocumentReference reference the same attachment' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end     
        
        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinicalnotes_found

        @attachment_url.each {|key, value| assert value[:flag], "Attachment #{key} referenced in DocumentReference/#{value[:id]} but not in any DiagnosticReport"}
      end
    end
  end
end
