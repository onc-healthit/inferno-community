# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4ClinicalNotesSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Clinical Notes Guideline Tests'

      description 'Verify that DocumentReference and DiagnosticReport resources on the FHIR server follow the US Core R4 Clinical Notes Guideline'

      test_id_prefix 'ClinicalNotes'

      requires :token, :patient_id
      conformance_supports :DocumentReference, :DiagnosticReport

      details %(

        The #{title} Sequence tests DiagnosticReport and DocumentReference resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [US Core Clinical Notes Guidance](https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html)

      )

      @clinical_notes_found = false

      def test_clinical_notes_document_reference(type_code)
        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinical_notes_found

        assert @actual_type_codes.include?(type_code), "Clinical Notes shall have at least one DocumentReference with type #{type_code}"
      end

      def test_clinical_notes_diagnostic_report(category_code)
        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinical_notes_found

        search_params = { 'patient': @instance.patient_id, 'category': category_code }
        resource_class = 'DiagnosticReport'
        @report_attachments = ClinicalNoteAttachment.new(resource_class)

        reply = get_resource_by_params(versioned_resource_class(resource_class), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        assert @resources_found, "Clinical Notes shall have at least one DiagnosticReport with category #{category_code}"

        diagnostic_reports = reply&.resource&.entry&.map { |entry| entry&.resource }

        diagnostic_reports&.each do |report|
          report&.presentedForm&.select { |attachment| !@report_attachments.attachment.key?(attachment&.url) }&.each do |attachment|
            @report_attachments.attachment[attachment.url] = report.id
          end
        end
      end

      test 'Server returns expected results from DocumentReference search by patient+clinicalnotes' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        search_params = { 'patient': @instance.patient_id, 'category': 'clinical-note' }
        resource_class = 'DocumentReference'

        @document_attachments = ClinicalNoteAttachment.new(resource_class)

        reply = get_resource_by_params(versioned_resource_class(resource_class), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @clinical_notes_found = true if resource_count.positive?

        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinical_notes_found

        document_references = reply&.resource&.entry&.map { |entry| entry&.resource }

        @required_type_codes = Set[
          '11488-4', # Consultation Note
          '18842-5', # Dischard Summary
          '34117-2', # History and physical note
          '28570-0', # Procedure note
          '11506-3' # Progress note
        ]

        @actual_type_codes = Set[]

        document_references&.select { |document| document&.type&.coding&.present? }&.each do |document|
          document.type.coding.select { |coding| coding&.system == 'http://loinc.org' && @required_type_codes.include?(coding&.code) }&.each do |coding|
            @actual_type_codes << coding.code

            document&.content&.select { |content| !@document_attachments.attachment.key?(content&.attachment&.url) }&.each do |content|
              @document_attachments.attachment[content.attachment.url] = document.id
            end
          end
        end
      end

      test 'Server shall have Consultation Notes' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('11488-4')
      end

      test 'Server shall have Discharge Summary' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('18842-5')
      end

      test 'Server shall have History and Physical Note' do
        metadata do
          id '04'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('34117-2')
      end

      test 'Server shall have Procedures Note' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('28570-0')
      end

      test 'Server shall have Progress Note' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('11506-3')
      end

      test 'Server returns Cardiology report from DiagnosticReport search by patient+category' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP29708-2')
      end

      test 'Server returns Pathology report from DiagnosticReport search by patient+category' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP7839-6')
      end

      test 'Server returns Radiology report from DiagnosticReport search by patient+category' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP29684-5')
      end

      test 'DiagnosticReport and DocumentReference reference the same attachment' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          desc %(
          )
          versions :r4
        end

        skip 'No Clinical Notes appear to be available for this patient. Please use patients with more information.' unless @clinical_notes_found

        assert_attachment_matched(@document_attachments, @report_attachments)
        assert_attachment_matched(@report_attachments, @document_attachments)
      end

      def assert_attachment_matched(source_attachments, target_attachments)
        not_matched_urls = source_attachments.attachment.keys - target_attachments.attachment.keys
        not_matched_attachments = not_matched_urls.map { |url| "#{url} in #{source_attachments.resource_class}/#{source_attachments.attachment[url]}" }

        assert not_matched_attachments.empty?, "Attachments #{not_matched_attachments.join(', ')} are not referenced in any #{target_attachments.resource_class}."
      end
    end

    class ClinicalNoteAttachment
      attr_reader :resource_class
      attr_reader :attachment

      def initialize(resource_class)
        @resource_class = resource_class
        @attachment = {}
      end
    end
  end
end
