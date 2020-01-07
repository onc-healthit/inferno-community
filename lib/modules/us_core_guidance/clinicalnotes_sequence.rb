# frozen_string_literal: true

module Inferno
  module Sequence
    class ClinicalNoteAttachment
      attr_reader :resource_class
      attr_reader :attachment

      def initialize(resource_class)
        @resource_class = resource_class
        @attachment = {}
      end
    end

    class USCoreR4ClinicalNotesSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Clinical Notes Guideline Tests'

      description 'Verify that DocumentReference and DiagnosticReport resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCCN'

      requires :token, :patient_id
      conformance_supports :DocumentReference, :DiagnosticReport

      details %(

        The #{title} Sequence tests DiagnosticReport and DocumentReference resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [US Core Clinical Notes Guidance](https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html)

      )

      attr_accessor :document_attachments

      @report_attachments = ClinicalNoteAttachment.new('DiagnosticReport')

      def test_clinical_notes_document_reference(category_code)
        search_params = { 'patient': @instance.patient_id, 'category': category_code }
        resource_class = 'DocumentReference'

        reply = get_resource_by_params(versioned_resource_class(resource_class), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0

        unless resource_count.positive?
          @skip_document_reference = true
          skip "This patient does not have #{resource_class} with category #{category_code}. Please use patients with more information."
        end

        @document_attachments = ClinicalNoteAttachment.new('DocumentReference') if document_attachments.nil?

        document_references = reply&.resource&.entry&.map { |entry| entry&.resource }

        document_references&.each do |document|
          document&.content&.select { |content| !@document_attachments.attachment.key?(content&.attachment&.url) }&.each do |content|
            @document_attachments.attachment[content.attachment.url] = document.id
          end
        end
      end

      def test_clinical_notes_diagnostic_report(category_code)
        search_params = { 'patient': @instance.patient_id, 'category': category_code }
        resource_class = 'DiagnosticReport'

        reply = get_resource_by_params(versioned_resource_class(resource_class), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0

        unless resource_count.postive?
          @skip_diagnostic_report = true
          skip "This patient does not have #{resource_class} with category #{category_code}. Please use patients with more information."
        end

        diagnostic_reports = reply&.resource&.entry&.map { |entry| entry&.resource }

        diagnostic_reports&.each do |report|
          report&.presentedForm&.select { |attachment| !@report_attachments.attachment.key?(attachment&.url) }&.each do |attachment|
            @report_attachments.attachment[attachment.url] = report.id
          end
        end
      end

      test :have_consultation_note do
        metadata do
          id '01'
          name 'Server shall have Consultation Notes'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|11488-4')
      end

      test 'Server shall have Discharge Summary' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|18842-5')
      end

      test 'Server shall have History and Physical Note' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|34117-2')
      end

      test 'Server shall have Procedures Note' do
        metadata do
          id '04'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|28570-0')
      end

      test 'Server shall have Progress Note' do
        metadata do
          id '05'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_document_reference('http://loinc.org|11506-3')
      end

      test 'Server returns Cardiology report from DiagnosticReport search by patient+category' do
        metadata do
          id '06'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP29708-2')
      end

      test 'Server returns Pathology report from DiagnosticReport search by patient+category' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP7839-6')
      end

      test 'Server returns Radiology report from DiagnosticReport search by patient+category' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        test_clinical_notes_diagnostic_report('http://loinc.org|LP29684-5')
      end

      test 'DiagnosticReport and DocumentReference reference the same attachment' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/us/core/clinical-notes-guidance.html'
          description %(
          )
          versions :r4
        end

        skip 'Not all required Clinical Notes appear to be available for this patient. Please use patients with more information.' if @skip_document_reference || @skip_diagnostic_report

        assert_attachment_matched(@document_attachments, @report_attachments)
        assert_attachment_matched(@report_attachments, @document_attachments)
      end

      def assert_attachment_matched(source_attachments, target_attachments)
        not_matched_urls = source_attachments.attachment.keys - target_attachments.attachment.keys
        not_matched_attachments = not_matched_urls.map { |url| "#{url} in #{source_attachments.resource_class}/#{source_attachments.attachment[url]}" }

        assert not_matched_attachments.empty?, "Attachments #{not_matched_attachments.join(', ')} are not referenced in any #{target_attachments.resource_class}."
      end
    end
  end
end
